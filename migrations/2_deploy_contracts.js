var Arbitrage = artifacts.require('./Arbitrage.sol')
let _ = '        '

module.exports = (deployer, network, accounts) => {
  deployer.then(async () => {
    try {

      params = deployer.network_id === 4 ? [
        '0xf5D915570BC477f9B8D6C0E980aA81757A3AaC36', // _uniFactory rinkeby
        '0x4e69969d9270ff55fc7c5043b074d4e45f795587' //_dutchXProxy rinkeby
      ] : [
        '0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95', // _uniFactory mainnet
        '0xaf1745c0f8117384dfa5fff40f824057c70f2ed3' //_dutchXProxy mainnet
       ]
 
      // Deploy Arbitrage.sol
      await deployer.deploy(Arbitrage, ...params)
      let arbitrage = await Arbitrage.deployed()
      console.log(_ + 'Arbitrage deployed at: ' + arbitrage.address)

    } catch (error) {
      console.log(error)
    }
  })
}
