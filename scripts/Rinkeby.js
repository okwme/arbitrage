var ArbitrageRinkeby = artifacts.require('./ArbitrageRinkeby.sol')

// const MockContract = artifacts.require('./MockContract.sol');
const IToken = artifacts.require('./interface/IToken.sol');
const IDutchExchange = artifacts.require('./interface/IDutchExchange.sol');
const IUniswapFactory = artifacts.require('./interface/IUniswapFactory.sol');
const IUniswapExchange = artifacts.require('./interface/IUniswapExchange.sol');

var BigNumber = require('bignumber.js')
let gasPrice = 1000000000 // 1GWEI

const _ = '        '
const emptyAdd = '0x' + '0'.repeat(40)
const deadline = '1649626618' // year 2022
module.exports = async function(callback) {
  let arbitrage, tx
  let from = '0x5899c1651653E1e4A110Cd45C7f4E9F576dE0670'
    try {
      var OMG = '0x00df91984582e6e96288307e9c2f20b38c8fece9'
      var dutchProxy = '0x4e69969D9270fF55fc7c5043B074d4e45F795587'
      var uniFactoryAddress = '0xf5D915570BC477f9B8D6C0E980aA81757A3AaC36'

      let dutchExchange = await IDutchExchange.at(dutchProxy);
      uniswapFactory = await IUniswapFactory.at(uniFactoryAddress)

      let omgToken = await IToken.at(OMG)

      // Deploy ArbitrageRinkeby.sol
      // arbitrage = await ArbitrageRinkeby.deployed()
      arbitrage = await ArbitrageRinkeby.new()


      let arbitrageDutch = await arbitrage.dutchXProxy()
      console.log({arbitrageDutch})

      let ethToken = await dutchExchange.ethToken()
      console.log({ethToken})

      // let wethToken = await IToken.at(ethToken)

      // tx = await wethToken.deposit({value: 1e17})

      tx = await arbitrage.depositEther({value: 1e17})
      console.log({tx})

      // let uniSwapExchangeAddress = await uniswapFactory.getExchange(iToken.address)

      // console.log(_ + 'uniSwapExchangeAddress: ' + uniSwapExchangeAddress)

      // let uniswapExchange = await IUniswapExchange.at(uniSwapExchangeAddress)
      
      // tx = await iToken.approve(uniswapExchange.address, 1e18.toString(10))


      // tx = await uniswapExchange.addLiquidity(0, 1e18.toString(10), deadline, {value: 1e18, from})
  
      // let tokensBought = await uniswapExchange.getEthToTokenInputPrice((1e18 / 2).toString(10))
      // console.log(_ + 'potential tokensBought for .5 ETH:' + tokensBought.toString())

      // let balanceOf = await iToken.balanceOf(from)
      // console.log(_ + 'OMG BALANCE: ' + balanceOf.toString(10))
      callback()
    } catch (error) {
      console.log(error)
      callback(error)
    }

}
