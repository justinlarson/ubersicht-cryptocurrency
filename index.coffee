###
    This URL should be "one size fits all"
###
command: """
    echo "[
        `curl -s https://api.coinmarketcap.com/v1/ticker/?limit=250`,
        `cat ~/.cryptoholdings.json`
    ]"
"""

refreshFrequency: '5m'

render: (output) ->
    holdingsArray = JSON.parse(output)[1]
    boxes = ""
    for coin, attrs of holdingsArray
        boxes += @genHtmlBox(attrs.ticker) + "\n"
    boxes += @genHtmlBox('total', 'USD')
    console.log(boxes)
    return boxes

###
    A method that generates a HTML block
    for a coin

    coinName - Name of a coin to generate box for (e.g. bitcoin)
    ticker - Ticker for a given coin (e.g. BTC). Defaults to coinName
###
genHtmlBox: (coinName, ticker = coinName) ->
    return """
    <div class='#{coinName.toLowerCase()} box '>
      <div class='ticker'> #{ticker.toUpperCase()}</div>
      <div class='badge lastUpdated' >Last Updated</div>
      <div class='price'></div>
    </div>
    """

###
    A function that gets current date in a form of HH:MM

    returns formatted date
###
getDate: () ->
    d = new Date()
    hours = d.getHours()
    mins = d.getMinutes()
    return "Updated: " + [
        (if hours > 9 then '' else '0') + hours,
        (if mins > 9 then '' else '0') + mins
    ].join(':')

update: (output, domEl) ->
  resArr = JSON.parse(output)[0]
  holdingsArray = JSON.parse(output)[1]
  fmtDate = @getDate()
  portfolio = 0

  for coin, attrs of holdingsArray
      coinRes = @findCoinResults(resArr, coin)
      box = $(domEl).find('.' + attrs.ticker.toLowerCase())
      info = @getPriceInfo(coinRes, attrs)
      portfolio += info.value
      @updateBox(box, info.html, fmtDate)

  # update 'total' portfolio value rounded to cents
  totalBox = $(domEl).find('.total')
  @updateBox(totalBox,'$'+ @numberWithCommas(@roundAmount(portfolio, 2)), fmtDate)

###
    Finds a coin to generate data for from json response

    jsonResponse - JSON with info about all coins
    coinName - name of a coin to search for
###
findCoinResults: (jsonResponse, coinName) ->
    for coin in jsonResponse
        if (coin['id'] == coinName)
            return coin
    return {}

###
    Sets date and value to a HTML box

    boxName - class name for a HTML box to update
    value - current price for a given coin
    date - date string when it was last updated
###
updateBox: (boxName, value, date) ->
    $(boxName).find('.price').html value
    $(boxName).find('.lastUpdated').html date

###
    Rounds a value to a number of decimals

    amount - number to round
    precision - number of numbers after decimal point
###
roundAmount: (amount, precision) ->
    prec = Math.pow(10, precision)
    rv = Math.round(amount * prec) / prec

    return rv

numberWithCommas: (x) ->
  y =if (x>1) then x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ","); else x 
  return y
###
    Gets price information for a given coin

    json - JSON object for a given coin
    coin - coin config from holdings

    returns JSON object containing HTML to be rendered
        and raw value of holdings
###
getPriceInfo: (json, coin) ->
  price = json['price_usd']
  change = json['percent_change_1h']
  change_24hr = json['percent_change_24h']
  change_7d = json['percent_change_7d']
  rank = json['rank']
  color = if (change >= 0) then 'green' else 'red'
  emoji =  if (change >= 0) then '🚀' else '🔻'
  emoji2 =  if (change_24hr >= 0) then '🚀' else '🔻'
  emoji3 =  if (change_7d >= 0) then '🚀' else '🔻'
  value = coin.holdings * price
  hodl = coin.holdings

  return {html: """
    <div class='price #{color}'>$ #{@numberWithCommas(@roundAmount(price, coin.round))}<div>
    <!--<div class='badge default'>Last Price</div>-->
    <div class='value '>$ #{@numberWithCommas(@roundAmount(value, 2))}</div>
    <div class='currency default'>Rank: #{rank } <br/>Hodling: #{@numberWithCommas(hodl)} <br/> 1HR:#{change}% #{emoji}  24HR: #{change_24hr}% #{emoji2} 7D: #{change_7d}% #{emoji3}</div>
  """, value: value}


style: """
  bottom: 0%
  left: 0%
  color: white
  font-family: 'Helvetica Neue'
  font-weight: 100
  text-align: left
  margin: 5px
  width: 250px
  text-align: center
  
  .box
    padding: 2px
    opacitiy: .3
    font-size: 18px
    
    .price
    
      font-size: 24px
    .ticker, .lastUpdated
      text-align: left
    .currency, .badge
      text-align: right
    .currency, .badge, .lastUpdated
      font-size: 8px
      font-weight: 500
      letter-spacing: 1px
    .ticker
      font-size: 10px
      font-weight: 500
      letter-spacing: 1px
      margin: 0px
      color: white
    .currency
        text-align: center
         
    .green
      color: white
      background-color: rgba(0, 255, 0, 0.5)
      
    .red
        background-color: rgba(255, 0, 0, 0.5)
        color: white
        
    .default
      color: white
"""
