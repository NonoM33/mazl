// A counting semaphore with a bounded waiting line. `run` starts the task when
// a permit is free, queues it (first come, first served) when the line has room,
// and refuses at once otherwise: under attack the work is shed, never piled up.

export class SemaphoreFullError extends Error {
  constructor() {
    super("semaphore: waiting line is full");
    this.name = "SemaphoreFullError";
  }
}

export interface SemaphoreOptions {
  // Tasks allowed to run at the same time.
  readonly permits: number;
  // Tasks allowed to wait for a permit.
  readonly maxQueue: number;
}

export interface Semaphore {
  run<T>(task: () => Promise<T>): Promise<T>;
  readonly active: number;
  readonly waiting: number;
}

export function createSemaphore(options: SemaphoreOptions): Semaphore {
  const { permits, maxQueue } = options;
  let active = 0;
  const line: Array<() => void> = [];

  function release(): void {
    const next = line.shift();
    if (next === undefined) active--;
    else next(); // the permit passes straight to the next in line
  }

  async function run<T>(task: () => Promise<T>): Promise<T> {
    if (active < permits) {
      active++;
    } else if (line.length < maxQueue) {
      await new Promise<void>((resolve) => line.push(resolve));
    } else {
      throw new SemaphoreFullError();
    }
    try {
      return await task();
    } finally {
      release();
    }
  }

  return {
    run,
    get active() { return active; },
    get waiting() { return line.length; },
  };
}
