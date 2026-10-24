import { createContext, useContext } from "react";

// Read by every member photo: in discreet mode the image leaves the DOM.
export interface DiscreetApi { readonly active: boolean; readonly enter: () => void; readonly exit: () => void }
export const DiscreetContext = createContext<DiscreetApi>({ active: false, enter: () => undefined, exit: () => undefined });
export const useDiscreet = (): DiscreetApi => useContext(DiscreetContext);
