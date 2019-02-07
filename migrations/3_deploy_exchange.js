var Arbitrage = artifacts.require('./Arbitrage.sol')
var IToken = artifacts.require('./IToken.sol')
var IUniswapFactory = artifacts.require('./IUniswapFactory.sol')
var IUniswapExchange = artifacts.require('./IUniswapExchange.sol')
let _ = '        '

const uniswapFactoryAddress = '0xdE5491f774F0Cb009ABcEA7326342E105dbb1B2E'

module.exports = (deployer, network, accounts) => {

  deployer.then(async () => {
    try {

      const uniswapFactory = await IUniswapFactory.at(uniswapFactoryAddress)
      const from = accounts[0]

      let iToken = await IToken.new()
      await iToken.deposit({value:1e18, from})

      await uniswapFactory.createExchange(iToken.address)

      let uniSwapExchangeAddress = await uniswapFactory.getExchange(iToken.address)

      console.log({uniSwapExchangeAddress})

      let uniswapExchange = await IUniswapExchange.at(uniSwapExchangeAddress)
      
      await iToken.approve(uniswapExchange.address, 1e18.toString(10))
      
      // function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);

      await uniswapExchange.addLiquidity(0, 1e18.toString(10), 1e18.toString(10), {value: 1e18, from})

      let balanceOf = await uniswapExchange.balanceOf(from)
      console.log(balanceOf.toString(10))


    } catch (error) {
      console.log(error)
    }
  })
}
