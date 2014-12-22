class MapView extends tg.Base
  constructor: (@mainScreen) ->
    @mainScreen.el.html('')

    @zoomLevel = 1
    @panzoomed = false

    @el = $('<div id="map-view" class="view">')
    @el.append $("""
      <div id="map-zoom-selector">
        <div class="trigger" data-zoom-level="2"></div>
        <div class="trigger current" data-zoom-level="1"></div>
      </div>
      <div id="map-content"></div>
    """)

    @mapContent = @el.find('#map-content')
    @mainScreen.el.append @el

    @_bindEvents()
    @render()

  _bindEvents: ->
    @el.on 'click', '#map-zoom-selector .trigger', (e) =>
      clicked = $(e.target)
      return if clicked.hasClass('current')

      clicked.siblings().removeClass('current')
      clicked.addClass('current')

      @zoomLevel = clicked.data('zoom-level')
      @render()

  render: ->
    if @zoomLevel == 1
      @_renderZoomLevel1()
    else
      @_renderZoomLevel2()


    if @panzoomed
      @mapContent.panzoom('resetDimensions')
      @mapContent.panzoom('resetPan')
      @mapContent.panzoom('resetZoom')
      @el.off 'mousewheel.focal'

    @mapContent.panzoom
      minScale: 0.25
      maxScale: 1
      transition: true
      increment: 0.01
      duration: 500
      contain: 'invert'

    @el.on 'mousewheel.focal', (e) =>
      e.preventDefault()

      delta = e.delta || e.originalEvent.wheelDelta
      zoomOut = if delta then delta < 0 else e.originalEvent.deltaY > 0

      @mapContent.panzoom 'zoom', zoomOut,
        increment: 0.1
        animate: false
        focal: e

    @panzoomed = true

    # center the map
    offX = -(@mapContent.outerWidth() / 2 - $('#main-screen').outerWidth() / 2)
    offY = -(@mapContent.outerHeight() / 2 - $('#main-screen').outerHeight() / 2)
    @mapContent.panzoom('pan', offX, offY)

  _renderZoomLevel1: ->
      @mapContent.html('zoomlevel1')

  _renderZoomLevel2: ->
    # snag the closest planet, along with a "nice" value to subtract from each planet's actual orbit
    closestPlanet = _.min tg.ghos.currentInfo.star.planets, (planet) -> planet.apogee
    planetSubVal = Math.log(closestPlanet.apogee) / Math.log(1.001) * 0.9

    farthestPlanet = _.max tg.ghos.currentInfo.star.planets, (planet) -> planet.apogee + planet.perigee

    @mapContent.html JST['views/map-view-zoom-2'](star: tg.ghos.currentInfo.star, planetSubVal: planetSubVal)

    @mapContent.css
      width: (Math.log(farthestPlanet.apogee) / Math.log(1.001) - planetSubVal) * 1.2
      height: (Math.log(farthestPlanet.apogee) / Math.log(1.001) - planetSubVal) * 1.2




window.tg.MapView = MapView