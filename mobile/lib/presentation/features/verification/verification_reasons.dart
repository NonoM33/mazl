/// French text for every refusal / error code of the verification endpoints
/// (docs/verification/CONTRAT.md: `FaceRejection`, `IdentityRejection`) and
/// for the client side failures of `HttpVerificationApi`.
String verificationReasonText(String? code) => switch (code) {
      'no_face' => 'Aucun visage détecté. Mets-toi face à la caméra, dans un endroit bien éclairé.',
      'multiple_faces' => 'Plusieurs visages détectés. Reste seul(e) dans le cadre.',
      'face_too_small' => 'Ton visage est trop loin. Rapproche-toi de la caméra.',
      'pose_mismatch' => 'Les poses demandées n\'ont pas été reconnues. Suis bien les consignes.',
      'duplicate_frames' => 'Les images sont trop semblables. Bouge la tête comme demandé.',
      'inconsistent_identity' => 'Les images ne montrent pas la même personne. Recommence seul(e).',
      'no_profile_photo' => 'Ajoute d\'abord à ton profil une photo où ton visage est bien visible.',
      'profile_mismatch' => 'Ton visage ne correspond pas à ta photo principale. Choisis une photo récente où tu es bien visible.',
      'daily_limit_reached' => 'Tu as atteint la limite d\'essais pour aujourd\'hui. Reviens demain.',
      'session_expired' => 'La session a expiré. Recommence.',
      'session_not_found' || 'session_used' => 'La session n\'est plus valide. Recommence.',
      'wrong_frame_count' || 'invalid_image' => 'Les images n\'ont pas pu être lues. Recommence.',
      'app_update_required' => 'Mets à jour l\'application pour vérifier ton profil.',
      'chip_data_invalid' || 'chip_signature_invalid' || 'csca_unknown' =>
        'La puce du document n\'a pas pu être authentifiée.',
      'document_expired' => 'Ce document est expiré.',
      'underage' => 'Tu dois avoir au moins 18 ans.',
      'document_already_used' => 'Ce document est déjà associé à un autre compte.',
      'document_banned' => 'Ce document ne peut pas être utilisé.',
      'document_face_mismatch' => 'Ton visage ne correspond pas à la photo du document.',
      'timeout' || 'network' => 'Connexion impossible. Vérifie ton réseau et réessaie.',
      _ => 'Une erreur est survenue. Réessaie dans un instant.',
    };
