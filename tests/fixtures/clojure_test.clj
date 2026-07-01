; Clojure file with semicolon and #| |# block comments
(defn calculate [x]
  #| Multi-line block comment
     spanning several lines
     with calculations |#
  (let [y (* x 2)]  ; inline comment

    ; standalone comment

    (+ y 10)))  ; mixed: code + comment

#| EOF block comment |#
