var Arbitrage = artifacts.require('./Arbitrage.sol')
var IToken = artifacts.require('./IToken.sol')
var IUniswapFactory = artifacts.require('./IUniswapFactory.sol')
var IUniswapExchange = artifacts.require('./IUniswapExchange.sol')
let _ = '        '

const uniswapFactoryAddress = '0xdE5491f774F0Cb009ABcEA7326342E105dbb1B2E'
const deadline = '1649626618' // 2022
module.exports = (deployer, network, accounts) => {

  deployer.then(async () => {
    try {

      const uniswapFactory = await IUniswapFactory.at(uniswapFactoryAddress)
      const from = accounts[0]

      let iToken = await IToken.new()
      console.log(_ + 'Uni Token Address: ' + iToken.address)

      await iToken.deposit({value:1e18, from})

      await uniswapFactory.createExchange(iToken.address)

      let uniSwapExchangeAddress = await uniswapFactory.getExchange(iToken.address)

      console.log({uniSwapExchangeAddress})

      let uniswapExchange = await IUniswapExchange.at(uniSwapExchangeAddress)
      
      await iToken.approve(uniswapExchange.address, 1e18.toString(10))

      tx = await uniswapExchange.addLiquidity(0, 1e18.toString(10), deadline, {value: 1e18, from})
      // let balanceOf = await uniswapExchange.balanceOf(from)
      // console.log(balanceOf.toString(10))


      // let tokensBought = await uniswapExchange.getEthToTokenInputPrice((1e18 / 2).toString(10))
      // console.log(_ + 'tokensBought:' + tokensBought.toString())
      // function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);

      await iToken.deposit({value:1e18, from})

      // tx = await uniswapExchange.ethToTokenSwapInput('1', deadline, {value: (1e18 / 2).toString(10)})
      // console.log({tx})
      // function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);

      let balanceOf = await iToken.balanceOf(from)
      console.log('UNI BALANCE:', balanceOf.toString(10))


    } catch (error) {
      console.log(error)
    }
  })
}
