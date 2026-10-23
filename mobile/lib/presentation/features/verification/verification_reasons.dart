/// French text for every refusal / error code of the verification endpoints
/// (docs/verification/CONTRAT.md: `FaceRejection`, `IdentityRejection`) and
/// for the client side failures of `HttpVerificationApi`.
String verificationReasonText(String? code) => switch (code) {
      'no_face' => 'Aucun visage détecté. Mettez-vous face à la caméra, dans un endroit bien éclairé.',
      'multiple_faces' => 'Plusieurs visages détectés. Restez seul(e) dans le cadre.',
      'face_too_small' => 'Votre visage est trop loin. Rapprochez-vous de la caméra.',
      'pose_mismatch' => 'Les poses demandées n\'ont pas été reconnues. Suivez bien les consignes.',
      'duplicate_frames' => 'Les images sont trop semblables. Bougez la tête comme demandé.',
      'inconsistent_identity' => 'Les images ne montrent pas la même personne. Recommencez seul(e).',
      'no_profile_photo' => 'Ajoutez d\'abord à votre profil une photo où votre visage est bien visible.',
      'profile_mismatch' => 'Votre visage ne correspond pas à votre photo principale. Choisissez une photo récente où vous êtes bien visible.',
      'daily_limit_reached' => 'Vous avez atteint la limite d\'essais pour aujourd\'hui. Revenez demain.',
      'session_expired' => 'La session a expiré. Recommencez.',
      'session_not_found' || 'session_used' => 'La session n\'est plus valide. Recommencez.',
      'wrong_frame_count' || 'invalid_image' => 'Les images n\'ont pas pu être lues. Recommencez.',
      'app_update_required' => 'Mettez à jour l\'application pour vérifier votre profil.',
      'chip_data_invalid' || 'chip_signature_invalid' || 'csca_unknown' =>
        'La puce du document n\'a pas pu être authentifiée.',
      'document_expired' => 'Ce document est expiré.',
      'underage' => 'Vous devez avoir au moins 18 ans.',
      'document_already_used' => 'Ce document est déjà associé à un autre compte.',
      'document_banned' => 'Ce document ne peut pas être utilisé.',
      'document_face_mismatch' => 'Votre visage ne correspond pas à la photo du document.',
      'timeout' || 'network' => 'Connexion impossible. Vérifiez votre réseau et réessayez.',
      _ => 'Une erreur est survenue. Réessayez dans un instant.',
    };
