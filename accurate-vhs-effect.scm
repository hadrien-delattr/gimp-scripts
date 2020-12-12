(define (script-fu-vhs-effect image layer rescale?)
    (let* ((width (car (gimp-image-width image)))
           (height (car (gimp-image-height image)))
           (image-type (car (gimp-image-base-type image)))
           (original-layer-name (car (gimp-item-get-name layer)))
           (bottom-layer (car (gimp-layer-copy layer FALSE)))
           (top-layer 0)
           (top-middle-layer 0)
           (final-layer 0)
           (gray-layer (car (gimp-layer-new image width height image-type "gray layer" 100 NORMAL-MODE)))
           (fg-color-backup (car (gimp-context-get-foreground)))
           )
        (begin
            (gimp-image-undo-group-start image)
            ; insert working copy layer (duplicate of the current layer)
            (gimp-image-insert-layer image bottom-layer 0 0)
            (gimp-item-set-name bottom-layer "bottom layer")
            ; resize the working copy to 640x480
            (gimp-layer-scale bottom-layer 640 480 FALSE)
            ; put a 50% gray layer on top of it
            (gimp-image-insert-layer image gray-layer 0 0)
            (gimp-layer-scale gray-layer 640 480 FALSE)
            (gimp-context-set-foreground '(127 127 127))
            (gimp-drawable-fill gray-layer FOREGROUND-FILL)
            (gimp-context-set-foreground fg-color-backup)
            ; insert a duplicate of the bottom layer on top
            (set! top-layer (car (gimp-layer-copy bottom-layer FALSE)))
            (gimp-image-insert-layer image top-layer 0 0)
            (gimp-item-set-name bottom-layer "top layer")
            ; desaturate and degrade the bottom layer
            (gimp-drawable-desaturate bottom-layer 2)
            (gimp-layer-scale bottom-layer 333 480 FALSE)
            (gimp-layer-scale bottom-layer 640 480 FALSE)
            ; merge the top and middle layer in color mode
            (gimp-layer-set-mode top-layer LAYER-MODE-LCH-COLOR)
            (set! top-middle-layer (car (gimp-image-merge-down image top-layer 0)))
            ; degrade the top-middle layer
            (gimp-layer-scale top-middle-layer 40 480 FALSE)
            (gimp-layer-scale top-middle-layer 640 480 FALSE)
            ; merge down the top-middle layer with the bottom layer in color mode
            (gimp-layer-set-mode top-middle-layer LAYER-MODE-LCH-COLOR)
            (set! final-layer (car (gimp-image-merge-down image top-middle-layer 0)))
            (gimp-item-set-name final-layer (string-append "VHS " original-layer-name))
            ; scale back to original size
            (if (= rescale? TRUE)
                (gimp-layer-scale final-layer width height FALSE)
            )
            ; Finish.
            (gimp-progress-end)
            (gimp-image-undo-group-end image)
            (gimp-displays-flush)
            final-layer
        )
    )
)

(script-fu-register
    "script-fu-vhs-effect"
    "VHS Effect"
    "Accurate VHS effect based on a recipe by JayyTT"
    "Hadrien Delattre"
    "Copyright 2020, Hadrien Delattre"
    "28/06/20"
    "RGB* GRAY*"
    SF-IMAGE "Image" 0
    SF-DRAWABLE "Layer" 0
    SF-TOGGLE "Rescale?" TRUE
)
(script-fu-menu-register "script-fu-vhs-effect" "<Image>/Filters/Artistic")
