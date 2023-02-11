(use-modules (gnu packages node)
             (gnu packages gettext)
             (gemmaro packages mdbook))

(packages->manifest (list node-lts po4a mdbook))
