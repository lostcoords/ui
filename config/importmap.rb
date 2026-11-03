# Everything lives under lostcoords/ui/*. Controllers are also pinned under the host's controllers/* key,
# so eagerLoadControllersFrom("controllers", application) registers them as lc-* identifiers. A host file
# with the same name, such as app/javascript/controllers/lc_dialog_controller.js, replaces the gem's.
pin "lostcoords/ui", to: "lostcoords/ui/index.js", preload: false
pin_all_from Lostcoords::Ui::Engine.root.join("app/javascript/lostcoords/ui/controllers"), under: "controllers", to: "lostcoords/ui/controllers", preload: false
pin_all_from Lostcoords::Ui::Engine.root.join("app/javascript/lostcoords/ui/helpers"), under: "lostcoords/ui/helpers", to: "lostcoords/ui/helpers", preload: false
# pin_all_from keeps one mapping per directory, so the namespaced controller keys are pinned one by one.
Dir[Lostcoords::Ui::Engine.root.join("app/javascript/lostcoords/ui/controllers/*.js")].each do |path|
  name = File.basename(path, ".js")
  pin "lostcoords/ui/controllers/#{name}", to: "lostcoords/ui/controllers/#{name}.js", preload: false
end
