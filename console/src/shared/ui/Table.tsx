import type { KeyboardEvent, ReactElement, ReactNode } from "react";

export interface Column<Row> {
  readonly key: string;
  readonly header: string;
  readonly render: (row: Row) => ReactNode;
  readonly width?: string;
  readonly align?: "left" | "right";
}

interface TableProps<Row> {
  readonly caption: string;
  readonly columns: readonly Column<Row>[];
  readonly rows: readonly Row[];
  readonly rowKey: (row: Row) => string | number;
  readonly onRowActivate?: (row: Row) => void;
  readonly selectedKey?: string | number | null;
}

export function Table<Row>({ caption, columns, rows, rowKey, onRowActivate, selectedKey = null }: TableProps<Row>): ReactElement {
  const onKey = (event: KeyboardEvent<HTMLTableRowElement>, row: Row): void => {
    if (onRowActivate !== undefined && (event.key === "Enter" || event.key === " ")) {
      event.preventDefault();
      onRowActivate(row);
    }
  };
  return (
    <div className="table-wrap">
      <table className="table">
        <caption className="sr-only">{caption}</caption>
        <colgroup>
          {columns.map((column) => (
            <col key={column.key} style={column.width === undefined ? undefined : { width: column.width }} />
          ))}
        </colgroup>
        <thead>
          <tr>
            {columns.map((column) => (
              <th key={column.key} scope="col" className={column.align === "right" ? "cell-right" : undefined}>
                {column.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => {
            const key = rowKey(row);
            const selected = key === selectedKey;
            return (
              <tr
                key={key}
                data-row-key={key}
                className={selected ? "is-selected" : undefined}
                aria-selected={onRowActivate === undefined ? undefined : selected}
                tabIndex={onRowActivate === undefined ? undefined : 0}
                onClick={onRowActivate === undefined ? undefined : () => onRowActivate(row)}
                onKeyDown={(event) => onKey(event, row)}
              >
                {columns.map((column) => (
                  <td key={column.key} className={column.align === "right" ? "cell-right" : undefined}>
                    {column.render(row)}
                  </td>
                ))}
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
