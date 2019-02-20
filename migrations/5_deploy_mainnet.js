var ArbitrageRinkeby = artifacts.require('./ArbitrageRinkeby.sol')
let _ = '        '

module.exports = (deployer, network, accounts) => {
  deployer.then(async () => {
    try {
      if(network !== 'mainnet') {
        console.log('Not on mainnet but on ' + network + ' instead')
        return
      }
 
      // Deploy ArbitrageRinkeby.sol
      await deployer.deploy(ArbitrageRinkeby)
      let arbitrage = await ArbitrageRinkeby.deployed()
      console.log(_ + 'ArbitrageRinkeby deployed at: ' + arbitrage.address)

    } catch (error) {
      console.log(error)
    }
  })
}