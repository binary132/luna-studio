eventListeners = []

export subscribeEvents = (listener) =>
    eventListeners.push listener

export class ModelView

    pushEvent: (path, event) =>
        for listener in eventListeners
            listener path, event

    attach: (scene) =>
        if scene.add?
            @view = scene.add @def
            @set @
            @registerEvents()
            @updateView()

    detach: (scene) =>
        @scene.remove @ref
        @view = null
