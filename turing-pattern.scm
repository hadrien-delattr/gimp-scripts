; Turing pattern generator script for GIMP
; based on the following recipe by Nobu Design:
; https://www.youtube.com/watch?v=NZNl6N7PnF4
; NOTE: at the time this script has been written (25/06/20), it seems that
; there is no high-pass filter accessible through script-fu (GIMP's high-pass
; filter is a GEGL operation, which is not accessible to script-fu).
; This script then relies on a high-pass filter implemented in Scheme by Rob
; Antonishen;
; https://www.silent9.com/blog/archives/152-High-Pass-Filter-Plugin.html
; https://gimper.net/resources/high-pass-filter.352/
; It is then necessary that the user also have this script for the Turing
; pattern script to work.

; FIXME: the progress bar doesnt work
(define (hp-threshold-blur-loop image layer layer-name iteration repeats diffusion)
        (begin
        (gimp-progress-update (/ iteration repeats))
        ; High-pass.
        (high-pass image layer
                   6 ; radius
                   0 ; mode
                   FALSE ; keep original layer?
        )
        ; High-pass changes the layer, so the handle provided as argument is no
        ; more valid. The layer on which to work has then to be found back
        ; based on its name.
        (set! layer (car (gimp-image-get-layer-by-name image layer-name)))
        ; Threshold.
        (gimp-drawable-threshold layer
                                 0 ; what is thresholded (value)
                                 0.5 ; min
                                 1.0 ; max
        )
        ; Blur.
        (plug-in-gauss RUN-NONINTERACTIVE image layer
                       diffusion ; horizontal radius
                       diffusion ; vertical radius
                       0 ; mode (IIRC)
        )
        ; Loop.
        (if (<= iteration repeats)
            (hp-threshold-blur-loop image layer layer-name (+ iteration 1) repeats diffusion))
        )
)

(define (script-fu-turing-pattern image repeats diffusion)
    (let* ((width (car (gimp-image-width image)))
           (height (car (gimp-image-height image)))
           (image-type (car (gimp-image-base-type image)))
           (layer (car (gimp-layer-new image width height image-type "turing-pattern" 100 NORMAL-MODE)))
           (layer-name (car (gimp-item-get-name layer)))
          )
          (begin
            (gimp-image-undo-group-start image)
            ; Add a layer to the current image.
            (gimp-drawable-fill layer BACKGROUND-FILL)
            (gimp-image-insert-layer image layer 0 0)
            ; Set the layer name to the name of the layer which is *actually*
            ; inserted. Indeed, the layer is supposed to be called
            ; "turing-pattern", but if there is already a layer named like
            ; that, GIMP will give it another name such as "turing-pattern #1".
            (set! layer-name (car (gimp-item-get-name layer)))
            ; Render perlin noise.
            (plug-in-solid-noise RUN-NONINTERACTIVE image layer
                                 TRUE ; tileable
                                 FALSE ; turbulent
                                 (random 2147483647) ; random seed
                                 3 ; detail level
                                 (min (* (/ width height) 8) 16) ; xsize
                                 (min (* (/ height width) 8) 16) ; ysize
            )
            ; Add noise.
            (plug-in-hsv-noise RUN-NONINTERACTIVE image layer
                               2 ; dulling
                               0 ; hue
                               0 ; saturation
                               58 ; value
            )
            ; Apply high-pass / threshold / blur cycle repeatedly.
            (hp-threshold-blur-loop image layer layer-name 1 repeats diffusion)
            ; Get the turing pattern layer handle.
            (set! layer (car (gimp-image-get-layer-by-name image layer-name)))
            ; Sharpen the layer.
            (plug-in-unsharp-mask RUN-NONINTERACTIVE image layer
                                  3 ; radius
                                  4 ; amount
                                  0 ; threshold
            )
            ; Finish.
            (gimp-progress-end)
            (gimp-image-undo-group-end image)
            (gimp-displays-flush)
          )
    )
)
(script-fu-register
    "script-fu-turing-pattern"
    "Turing Pattern"
    "Generates Turing patterns"
    "Hadrien Delattre"
    "Copyright 2020, Hadrien Delattre"
    "25/06/20"
    "RGB* GRAY*"
    SF-IMAGE "Image" 0
    SF-ADJUSTMENT "Repeats" '(10 1 100 1 10 1 0)
    SF-ADJUSTMENT "Diffusion" '(7 1 15 1 3 1 0)
)
(script-fu-menu-register "script-fu-turing-pattern" "<Image>/Filters/Render")
