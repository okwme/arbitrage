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

contract('Debug', function(accounts) {
  let arbitrage

  it('should pass', async () => {
    

    // Deploy Arbitrage.sol
    console.log("Deploy ...")
    arbitrage = await Arbitrage.new("0xdE5491f774F0Cb009ABcEA7326342E105dbb1B2E", "0xa4392264a2d8c998901d10c154c91725b1bf0158")
    console.log("Deposit Ether ...")
    await arbitrage.depositEther({ value:1e18 })
    console.log("Execute opportunity ...")
    tx = await arbitrage.dutchOpportunity('0x8273e4B8ED6c78e252a9fCa5563Adfcc75C91b2A', '990000000000001')
    console.log(tx)

    // We force failure to print events
    assert(false)
  })

})
