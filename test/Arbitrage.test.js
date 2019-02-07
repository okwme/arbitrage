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

contract('Arbitrage', function(accounts) {
  let arbitrage

  let iToken
  let iDutchExchange
  let mockDutchExchange
  let iUniswapFactory
  let mockUniswapFactory
  let iUniswapExchange
  let mockUniswapExchange

  before(async () => {
      try {
        var totalGas = new BigNumber(0)

        // Create Mocks
        mockEthToken = await MockContract.new()
        var tx = await web3.eth.getTransactionReceipt(mockEthToken.transactionHash)
        totalGas = totalGas.plus(tx.gasUsed)
        console.log(_ + tx.gasUsed + ' - Deploy mockEthToken')

        mockDutchExchange = await MockContract.new()
        tx = await web3.eth.getTransactionReceipt(mockDutchExchange.transactionHash)
        totalGas = totalGas.plus(tx.gasUsed)
        console.log(_ + tx.gasUsed + ' - Deploy mockDutchExchange')

        mockUniswapFactory = await MockContract.new()
        tx = await web3.eth.getTransactionReceipt(mockUniswapFactory.transactionHash)
        totalGas = totalGas.plus(tx.gasUsed)
        console.log(_ + tx.gasUsed + ' - Deploy mockUniswapFactory')

        mockUniswapExchange = await MockContract.new()
        tx = await web3.eth.getTransactionReceipt(mockUniswapExchange.transactionHash)
        totalGas = totalGas.plus(tx.gasUsed)
        console.log(_ + tx.gasUsed + ' - Deploy mockUniswapExchange')

        // Deploy interfaces for building mock methods
        iToken = await IToken.at(mockEthToken.address)
        iDutchExchange = await IDutchExchange.at(mockDutchExchange.address);
        iUniswapFactory = await IUniswapFactory.at(mockUniswapFactory.address);
        iUniswapExchange = await IUniswapExchange.at(mockUniswapExchange.address);

        // Deploy Arbitrage.sol
        arbitrage = await Arbitrage.new(iUniswapFactory.address, iDutchExchange.address)
        tx = await web3.eth.getTransactionReceipt(arbitrage.transactionHash)
        totalGas = totalGas.plus(tx.gasUsed)
        console.log(_ + tx.gasUsed + ' - Deploy arbitrage')
        arbitrage = await Arbitrage.deployed()

        console.log(_ + '-----------------------')
        console.log(_ + totalGas.toFormat(0) + ' - Total Gas')
        // done()
      } catch (error) {
        console.error(error)
        // done(false)
      }
  })


    it('should pass', async () => {
      const depositAmount = 1


      const ethToken = iDutchExchange.contract.methods.ethToken().encodeABI()
      await mockDutchExchange.givenMethodReturnAddress(ethToken, mockEthToken.address)

      const deposit = iToken.contract.methods.deposit().encodeABI()
      await mockEthToken.givenMethodReturn(deposit, [])

      const approve = iToken.contract.methods.approve(emptyAdd, 0).encodeABI()
      await mockEthToken.givenMethodReturnBool(approve, true)

      const dutchDeposit = iDutchExchange.contract.methods.deposit(emptyAdd, 0).encodeABI()
      await mockDutchExchange.givenMethodReturnUint(dutchDeposit, depositAmount)

      await arbitrage.depositEther({value: depositAmount})

    })

})

function getBlockNumber() {
  return new Promise((resolve, reject) => {
    web3.eth.getBlockNumber((error, result) => {
      if (error) reject(error)
      resolve(result)
    })
  })
}

function increaseBlocks(blocks) {
  return new Promise((resolve, reject) => {
    increaseBlock().then(() => {
      blocks -= 1
      if (blocks == 0) {
        resolve()
      } else {
        increaseBlocks(blocks).then(resolve)
      }
    })
  })
}

function increaseBlock() {
  return new Promise((resolve, reject) => {
    web3.currentProvider.sendAsync(
      {
        jsonrpc: '2.0',
        method: 'evm_mine',
        id: 12345
      },
      (err, result) => {
        if (err) reject(err)
        resolve(result)
      }
    )
  })
}

function decodeEventString(hexVal) {
  return hexVal
    .match(/.{1,2}/g)
    .map(a =>
      a
        .toLowerCase()
        .split('')
        .reduce(
          (result, ch) => result * 16 + '0123456789abcdefgh'.indexOf(ch),
          0
        )
    )
    .map(a => String.fromCharCode(a))
    .join('')
}
