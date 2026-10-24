export function Switch({ checked, onChange, label, disabled = false }: { readonly checked: boolean; readonly onChange: (next: boolean) => void; readonly label: string; readonly disabled?: boolean }) {
  return (
    <span className="switch">
      <input type="checkbox" role="switch" checked={checked} disabled={disabled} aria-label={label} onChange={(event) => onChange(event.target.checked)} />
      <span className="track"><span className="thumb" /></span>
    </span>
  );
}
