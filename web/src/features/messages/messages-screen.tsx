import { ScreenHeader } from "../../app/shell";

// Placeholder, replaced in lot 5.
export function MessagesScreen({ conversationId }: { readonly conversationId: number | null }) {
  return <ScreenHeader title={conversationId === null ? "Messages" : `Conversation ${conversationId}`} />;
}
