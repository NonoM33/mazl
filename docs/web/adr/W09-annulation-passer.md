# ADR-W09 — « Annuler » (Z) sans route d'annulation

Date : 2026-10-24. Statut : accepté.

L'API n'a pas de route pour annuler un swipe. Sur le web, un « passer » n'est envoyé qu'après
**5 secondes** (barre « Profil passé · Annuler (Z) ») ; Z pendant ce délai remet la carte, et
rien n'a été écrit côté serveur. Un like et un Super Like partent tout de suite (un match doit
s'afficher sans attendre) et ne s'annulent pas. Quitter la page envoie les « passer » en
attente (`fetch` avec `keepalive`). Pas de privilège mazl+ ici : ce n'est pas le « Revenir en
arrière » du mobile, qui demanderait une route serveur (à faire dans le matching).
