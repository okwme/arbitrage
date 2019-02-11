var Arbitrage = artifacts.require('./Arbitrage.sol')

const MockContract = artifacts.require('./MockContract.sol');
const IToken = artifacts.require('./interface/IToken.sol');
const IDutchExchange = artifacts.require('./interface/IDutchExchange.sol');
const IUniswapFactory = artifacts.require('./interface/IUniswapFactory.sol');
const IUniswapExchange = artifacts.require('./interface/IUniswapExchange.sol');

var BigNumber = require('bignumber.js')
let gasPrice = 1000000000 // 1GWEI

const _ = '        '
const emptyAdd = '0x' + '0'.repeat(40)
console.log('"?????')
contract('Debug', function(accounts) {
  let arbitrage

  it('should pass', async () => {
    try {




      uniswapFactory = await IUniswapFactory.at('0xdE5491f774F0Cb009ABcEA7326342E105dbb1B2E')
      // Deploy Arbitrage.sol
      console.log("Deploy ...")
      arbitrage = await Arbitrage.new("0xdE5491f774F0Cb009ABcEA7326342E105dbb1B2E", "0xa4392264a2d8c998901d10c154c91725b1bf0158")
      console.log("Deposit Ether ...")
      await arbitrage.depositEther({ value:1e18 })
      console.log("Execute opportunity ...")
      // tx = await arbitrage.uniswapOpportunity('0x8273e4B8ED6c78e252a9fCa5563Adfcc75C91b2A', '990000000000001')
      // console.log(tx.receipt.rawLogs)
      // 373083712375058828
      // 284345144034671943

      // 440000000000000001
      var exchange = await uniswapFactory.getExchange('0x8273e4B8ED6c78e252a9fCa5563Adfcc75C91b2A')
      var uniswapExchange = await IUniswapExchange.at(exchange)
      var EthAmount = await uniswapExchange.getTokenToEthOutputPrice('330000000000000001')
      console.log('TokenToEth', EthAmount.toString(10))

      console.log('Ether Spent on Opp', '283791165594153088')
      tx = await arbitrage.dutchOpportunity.call('0x8273e4B8ED6c78e252a9fCa5563Adfcc75C91b2A', '374289831206257697')
      console.log('return', tx.toString(10))

      // We force failure to print events
      assert(false)
    } catch (error) {
      console.log(error)
    }
  })

})
