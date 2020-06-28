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
(define (hp-threshold-blur-loop image layer layer-name iteration repeats diffusion hp-radius)
        (begin
        (gimp-progress-update (/ iteration repeats))
        ; High-pass.
        (high-pass image layer
                   hp-radius ; radius
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
            (hp-threshold-blur-loop image layer layer-name (+ iteration 1) repeats diffusion hp-radius))
        )
)

(define (script-fu-turing-pattern image layer repeats diffusion hp-radius create-new-layer?)
    (let* ((width (car (gimp-image-width image)))
           (height (car (gimp-image-height image)))
           (image-type (car (gimp-image-base-type image)))
           (layer-name (car (gimp-item-get-name layer)))
          )
          (begin
            (gimp-image-undo-group-start image)
            (if (= create-new-layer? TRUE)
                (begin
                  ; Add a layer to the current image.
                  ; The `layer` variable now points to this new layer instead
                  ; of the one provided as parameter.
                  (set! layer (car (gimp-layer-new image width height image-type "turing-pattern" 100 NORMAL-MODE)))
                  ; Insert the new layer in the stack of the current image.
                  (gimp-image-insert-layer image layer 0 0)
                  ; Fill it with perlin noise.
                  (plug-in-solid-noise RUN-NONINTERACTIVE image layer
                                       TRUE ; tileable
                                       FALSE ; turbulent
                                       (random 2147483647) ; random seed
                                       3 ; detail level
                                       (min (* (/ width height) 8) 16) ; xsize
                                       (min (* (/ height width) 8) 16) ; ysize
                  )
                  ; Add value noise.
                  (plug-in-hsv-noise RUN-NONINTERACTIVE image layer
                                     2 ; dulling
                                     0 ; hue
                                     0 ; saturation
                                     58 ; value
                  )
                )
            )
            ; If a new layer is inserted, its name is supposed to be
            ; "turing-pattern". However if there is already a layer with that
            ; name, GIMP will name it something like "turing-pattern #1". It
            ; is then necessary to get the name of the layer which is actually
            ; inserted.
            (set! layer-name (car (gimp-item-get-name layer)))
            ; Apply high-pass / threshold / blur cycle repeatedly.
            (hp-threshold-blur-loop image layer layer-name 1 repeats diffusion hp-radius)
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
            layer
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
    SF-DRAWABLE "Layer" 0
    SF-ADJUSTMENT "Repeats" '(10 1 100 1 10 1 0)
    SF-ADJUSTMENT "Diffusion" '(7 1 30 1 3 1 0)
    SF-ADJUSTMENT "High-Pass Radius" '(6 4 50 1 5 1 0)
    SF-TOGGLE "Create new layer?" TRUE
)
(script-fu-menu-register "script-fu-turing-pattern" "<Image>/Filters/Render")
