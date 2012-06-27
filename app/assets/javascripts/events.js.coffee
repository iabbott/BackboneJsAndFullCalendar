jQuery ->

  class Event extends Backbone.Model
    # nothing

  class Events extends Backbone.Collection
    model: Event
    url: 'events'

  class EventsView extends Backbone.View
    initialize: ->
      _.bindAll(this)
      @collection.bind 'reset',   @addAll
      @collection.bind 'add',     @addOne
      @collection.bind 'change',  @change
      @collection.bind 'destroy', @destroy
      @eventView = new EventView()

    render: ->
      @el.fullCalendar
        header:
          left: 'prev,next today'
          center: 'title'
          right: 'month,agendaWeek,agendaDay'
        selectable: true
        selectHelper: true
        editable: true
        ignoreTimezone: false
        select: @select
        eventClick: @eventClick
        eventDrop: @eventDropOrResize
        eventResize: @eventDropOrResize

    addAll: ->
      @el.fullCalendar 'addEventSource', @collection.toJSON()

    addOne: (event) ->
      @el.fullCalendar 'renderEvent', event.toJSON(), true

    select: (startDate, endDate) ->
      @eventView.collection = @collection;
      @eventView.model = new Event start: startDate, end: endDate
      @eventView.render()

    eventClick: (fcEvent) ->
      @eventView.model = @collection.get fcEvent.id
      @eventView.render()

    change: (event) ->
      # Look up the underlying event in the calendar and update its details from the model
      fcEvent = @el.fullCalendar('clientEvents', event.get('id'))[0]
      fcEvent.title = event.get 'title'
      fcEvent.color = event.get 'color'
      @el.fullCalendar 'updateEvent', fcEvent

    eventDropOrResize: (fcEvent) ->
      # Lookup the model that has the ID of the event and update its attributes
      @collection.get(fcEvent.id).save start: fcEvent.start, end: fcEvent.end

    destroy: (event) ->
      @el.fullCalendar 'removeEvents', event.id

  class EventView extends Backbone.View
      el: $('#eventDialog')

      initialize: ->
        _.bindAll(this);

      render: ->
        buttons =
          'Ok': @save
        unless @model.isNew()
          _.extend buttons, { 'Delete': @destroy }
        _.extend buttons, { 'Cancel': @close }

        @el.dialog
          modal: true,
          title: (@model.isNew() ? 'New' : 'Edit') + ' Event',
          buttons: buttons,
          open: @open
        return this

      open: ->
        @$('#title').val(@model.get 'title')
        @$('#color').val(@model.get 'color')

      save: ->
        @model.set({'title': @$('#title').val(), 'color': @$('#color').val()});
        if @model.isNew()
          @collection.create @model, { success: @close }
        else
          @model.save {}, {success: @close}

      close: ->
        @el.dialog 'close'

      destroy: ->
        @model.destroy success: @close

  events = new Events()
  new EventsView({el: $("#calendar"), collection: events}).render()
  events.fetch()
