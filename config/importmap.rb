# Keys match the host's own helpers/ and controllers/ pins, so imports and stimulus-loading resolve the same way.
pin_all_from Lostcoords::Ui::Engine.root.join("app/javascript/lostcoords/ui/controllers"), under: "controllers", to: "lostcoords/ui/controllers", preload: false
pin_all_from Lostcoords::Ui::Engine.root.join("app/javascript/lostcoords/ui/helpers"), under: "helpers", to: "lostcoords/ui/helpers", preload: false
