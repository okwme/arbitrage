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
const deadline = '1749626618' // year 2022
module.exports = async function(callback) {
  let arbitrage, tx
  let from = '0x5899c1651653E1e4A110Cd45C7f4E9F576dE0670'
    try {
      var OMG = '0x00df91984582e6e96288307e9c2f20b38c8fece9'
      var RDN = '0x3615757011112560521536258c1e7325ae3b48ae'
      var dutchProxy = '0xaAEb2035FF394fdB2C879190f95e7676f1A9444B'
      var uniFactoryAddress = '0xf5D915570BC477f9B8D6C0E980aA81757A3AaC36'

      let dutchExchange = await IDutchExchange.at(dutchProxy);
      uniswapFactory = await IUniswapFactory.at(uniFactoryAddress)

      let omgToken = await IToken.at(OMG)
      let rdnToken = await IToken.at(RDN)

      // Deploy ArbitrageRinkeby.sol
      arbitrage = await ArbitrageRinkeby.deployed()
      // arbitrage = await ArbitrageRinkeby.new()


      // let arbitrageDutch = await arbitrage.dutchXProxy()
      // console.log({arbitrageDutch})

      // let ethToken = await dutchExchange.ethToken()
      // console.log({ethToken})

      // let wethToken = await IToken.at(ethToken)

      // tx = await wethToken.deposit({value: 1e17})

      // tx = await arbitrage.depositEther({value: 1e17})
      // console.log({tx})

      // tx = await uniswapFactory.createExchange(RDN)
      // console.log('uniswapFactory.createExchange', tx)

      let uniSwapExchangeAddress = await uniswapFactory.getExchange(rdnToken.address)
      console.log(_ + 'uniSwapExchangeAddress: ' + uniSwapExchangeAddress)

      let uniswapExchange = await IUniswapExchange.at(uniSwapExchangeAddress)
      
      ethReserve = await web3.eth.getBalance(uniSwapExchangeAddress)
      console.log({ethReserve})

      tokenReserve = await rdnToken.balanceOf(uniSwapExchangeAddress)
      console.log({tokenReserve})


      allowance = await rdnToken.allowance(from, uniSwapExchangeAddress)
      console.log({allowance})

      liquidity = await uniswapExchange.balanceOf(from)
      console.log(_ + 'uniswapExchange liquidity: ' + liquidity.toString(10))



      // tx = await rdnToken.approve(uniswapExchange.address, 1e20.toString(10))
      // console.log('rdnToken.approve', tx.receipt.status)


      // allowance = await rdnToken.allowance(from, uniSwapExchangeAddress)
      // console.log({allowance})

      let balanceOf = await rdnToken.balanceOf(from)
      console.log(_ + 'rdn BALANCE: ' + balanceOf.toString(10))

      // tx = await uniswapExchange.addLiquidity('0', (1e10).toString(10), deadline, {value: (1e10).toString(10)})
      // console.log('uniswapExchange.addLiquidity', tx.receipt.status)
  
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
