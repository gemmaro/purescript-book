(use-modules (gnu packages node)
             (gnu packages gettext))

(packages->manifest (list node-lts po4a))
