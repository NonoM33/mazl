import { useCallback, useEffect, useRef, useState } from "react";
import { api, request } from "../../shared/api/client";
import { ApiError, describeError } from "../../shared/api/errors";
import type { OwnPhoto, PhotosResponse } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { fileProblem, MAX_PHOTOS, moveBy, moveTo, rejectionMessage } from "./photo-order";

// The member's photos: list, upload (with a local preview while it travels),
// reorder and delete. Signed URLs live in memory only and are reloaded by
// useResource before they expire.

const NO_PHOTOS: readonly OwnPhoto[] = [];

export interface PendingUpload { readonly key: string; readonly preview: string }

function orderOf(photos: readonly OwnPhoto[]): readonly number[] {
  return photos.map((photo) => photo.id);
}

function applyOrder(photos: readonly OwnPhoto[], ids: readonly number[]): readonly OwnPhoto[] {
  return ids.flatMap((id, index) => {
    const photo = photos.find((item) => item.id === id);
    return photo ? [{ ...photo, position: index, is_primary: index === 0 }] : [];
  });
}

function uploadMessage(error: unknown): string {
  if (error instanceof ApiError) {
    const reason = error.body.reason;
    return rejectionMessage(error.status, reason) ?? describeError(error);
  }
  return describeError(error);
}

export function usePhotos() {
  const resource = useResource<readonly OwnPhoto[]>("own-photos", async (signal) => (await api.get<PhotosResponse>("/api/profile/photos", signal)).photos);
  const [pending, setPending] = useState<readonly PendingUpload[]>([]);
  const [message, setMessage] = useState<string | null>(null);
  const [announcement, setAnnouncement] = useState("");
  const counter = useRef(0);
  const previews = useRef(new Set<string>());
  const photos = resource.state.data ?? NO_PHOTOS;
  const { mutate, reload } = resource;

  useEffect(() => {
    const live = previews.current;
    return () => { for (const url of live) URL.revokeObjectURL(url); };
  }, []);

  const uploadOne = useCallback(async (file: File) => {
    const preview = URL.createObjectURL(file);
    previews.current.add(preview);
    counter.current += 1;
    const key = `upload-${counter.current}`;
    setPending((current) => [...current, { key, preview }]);
    try {
      const form = new FormData();
      form.append("photo", file);
      await request("/api/profile/photos", { method: "POST", body: form });
      await reload();
    } catch (error) {
      setMessage(uploadMessage(error));
    } finally {
      setPending((current) => current.filter((item) => item.key !== key));
      previews.current.delete(preview);
      URL.revokeObjectURL(preview);
    }
  }, [reload]);

  const upload = useCallback(async (files: readonly File[]) => {
    setMessage(null);
    let room = MAX_PHOTOS - photos.length - pending.length;
    for (const file of files) {
      const problem = fileProblem(file);
      if (problem) { setMessage(`${file.name} : ${problem}`); continue; }
      if (room <= 0) { setMessage(rejectionMessage(409, undefined)); break; }
      room -= 1;
      await uploadOne(file);
    }
  }, [photos.length, pending.length, uploadOne]);

  const reorder = useCallback(async (next: readonly number[]) => {
    const before = orderOf(photos);
    if (next.join() === before.join()) return;
    mutate((current) => applyOrder(current, next));
    setMessage(null);
    try {
      await api.put("/api/profile/photos/reorder", { photoIds: [...next] });
      setAnnouncement(`Photo déplacée. L'ordre est enregistré.`);
    } catch (error) {
      setMessage(describeError(error));
      await reload();
    }
  }, [photos, mutate, reload]);

  const move = useCallback(async (id: number, delta: -1 | 1) => {
    const next = moveBy(orderOf(photos), id, delta);
    await reorder(next);
    const position = next.indexOf(id) + 1;
    setAnnouncement(`Photo déplacée en position ${position} sur ${next.length}.`);
  }, [photos, reorder]);

  const dropAt = useCallback(async (id: number, index: number) => reorder(moveTo(orderOf(photos), id, index)), [photos, reorder]);

  const remove = useCallback(async (id: number) => {
    setMessage(null);
    try {
      await api.delete(`/api/profile/photos/${id}`);
      await reload();
    } catch (error) {
      setMessage(describeError(error));
    }
  }, [reload]);

  return { state: resource.state, photos, pending, message, announcement, upload, move, dropAt, remove, reload };
}
