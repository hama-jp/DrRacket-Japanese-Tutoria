#lang racket
(require pict)
(require racket/draw)

(define (save-pict p path)
  (send (pict->bitmap p) save-file path 'png))

;; 1. 基本図形
(save-pict (circle 80)       "/home/user/DrRacket-Japanese-Tutoria/images/ch13/01-circle.png")
(save-pict (rectangle 120 60) "/home/user/DrRacket-Japanese-Tutoria/images/ch13/02-rect.png")

;; 2. 塗りと色
(save-pict (colorize (filled-rectangle 100 60) "coral")
           "/home/user/DrRacket-Japanese-Tutoria/images/ch13/03-filled.png")

;; 3. 合成
(save-pict (hc-append 20
                      (colorize (filled-rectangle 60 60) "tomato")
                      (colorize (disk 60) "royalblue")
                      (colorize (filled-rectangle 60 60) "olivedrab"))
           "/home/user/DrRacket-Japanese-Tutoria/images/ch13/04-hcappend.png")

(save-pict (vc-append 10
                      (colorize (filled-rectangle 100 30) "tomato")
                      (colorize (filled-rectangle 100 30) "gold")
                      (colorize (filled-rectangle 100 30) "dodgerblue"))
           "/home/user/DrRacket-Japanese-Tutoria/images/ch13/05-vcappend.png")

;; 4. 回転
(save-pict (rotate (colorize (filled-rectangle 100 40) "teal") (/ pi 6))
           "/home/user/DrRacket-Japanese-Tutoria/images/ch13/06-rotate.png")

;; 5. パターン:チェック盤
(define (tile color1 color2)
  (hc-append (colorize (filled-rectangle 40 40) color1)
             (colorize (filled-rectangle 40 40) color2)))
(define row1 (apply hc-append (make-list 4 (tile "black" "white"))))
(define row2 (apply hc-append (make-list 4 (tile "white" "black"))))
(define board (apply vc-append (for/list ([i (in-range 4)])
                                 (if (even? i) row1 row2))))
(save-pict board "/home/user/DrRacket-Japanese-Tutoria/images/ch13/07-checker.png")

;; 6. 再帰図形(シェルピンスキー三角形っぽい)
(require (only-in racket/draw the-color-database))
(define (sierpinski n)
  (cond
    [(= n 0)
     (colorize (filled-rectangle 4 4) "darkslateblue")]
    [else
     (let ([small (sierpinski (- n 1))])
       (vc-append (hc-append small small)
                  (hc-append small (ghost small))))]))
(save-pict (sierpinski 5) "/home/user/DrRacket-Japanese-Tutoria/images/ch13/08-sierpinski.png")

(displayln "all saved")
