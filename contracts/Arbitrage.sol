pragma solidity ^0.5.0;

import "./IUniswapExchange.sol";
import "./IUniswapFactory.sol";
import "./IDutchExchange.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * The Arbitrage contract
 */

contract Arbitrage is Ownable {
    
    IUniswapFactory uniFactory;
    IDutchExchange dutchXProxy;

    constructor(IUniswapFactory _uniFactory, IDutchExchange _dutchXProxy) public {
        uniFactory = _uniFactory;
        dutchXProxy = _dutchXProxy;
    }


    function() external payable {
        // depositEther();
    }

    function depositEther() public payable {
        uint balance = address(this).balance;

        // deposit balance to weth
        address weth = dutchXProxy.ethToken();
        (bool success, bytes memory returnData) = weth.call.value(balance).gas(200000)("");
        require(success, "sending ether didn't work");

        // approve max to weth for dutchX
        uint256 max = 0;
        bytes memory  payload = abi.encodeWithSignature("approve(address,uint)",address(dutchXProxy), max - 1);
        (success,returnData) = weth.call.value(0).gas(200000)(payload);
        require(success, "approve ether didn't work");

        // trigger deposit on dutchX, make sure there's at least the amount we deposited
        uint newBalance = dutchXProxy.deposit(weth, balance);
        require(newBalance >= balance, "deposit didn't work");
    }

    function _withdrawEther(uint amount) internal {
        address weth = dutchXProxy.ethToken();
        bytes memory  payload = abi.encodeWithSignature("withdraw(uint)", amount);
        (bool success, bytes memory returnData) = weth.call.value(0).gas(200000)(payload);
        require(success, "withdraw didn't work");
    }

    function transferEther(address payable recepient, uint amount) public onlyOwner {
        _withdrawEther(amount);
        recepient.transfer(amount);
    }

    function depositToken(address token, uint amount) public onlyOwner {

        uint256 max = 0;
        bytes memory  payload = abi.encodeWithSignature("approve(address,uint)",address(dutchXProxy), max - 1);
        (bool success, bytes memory returnData) = token.call.value(0).gas(200000)(payload);
        require(success, "approve didn't work");

        uint newBalance = dutchXProxy.deposit(token, amount);
        require(newBalance >= amount, "deposit didn't work");
    }

    function transferToken(address token, address recepient, uint amount) public onlyOwner {
        bytes memory  payload = abi.encodeWithSignature("transfer(address,uint)", recepient, amount);
        (bool success, bytes memory returnData) = token.call.value(0).gas(200000)(payload);
        require(success, "transfer didn't work");
    }

    function dutchOpportunity(address token1, uint256 amount) public {

        address token2 = dutchXProxy.ethToken();
        uniFactory.getExchange(token1);
        address uniswapExchange = uniFactory.getExchange(token1);
        uint256 dutchAuctionIndex = dutchXProxy.getAuctionIndex(token1, token2);
        uint256 tokensBought = dutchXProxy.postBuyOrder(token2, token1, dutchAuctionIndex, amount);
        uint256 etherReturned = IUniswapExchange(uniswapExchange).tokenToEthSwapInput(tokensBought, amount, block.timestamp);
        require(etherReturned >= amount, "no profit");
        depositEther();
    }


    function uniswapOpportunity(address token1, uint256 amount) public {
        _withdrawEther(amount);
        require(address(this).balance == amount, "buying from uniswap takes real Ether");

        address token2 = dutchXProxy.ethToken();
        address uniswapExchange = uniFactory.getExchange(token1);
        uint256 dutchAuctionIndex = dutchXProxy.getAuctionIndex(token1, token2);

        uint256 tokensBought = IUniswapExchange(uniswapExchange).ethToTokenSwapInput.value(amount)(0, block.timestamp);

        uint256 etherReturned;
        (dutchAuctionIndex, etherReturned) = dutchXProxy.postSellOrder(token1, token2, dutchAuctionIndex, tokensBought);
        require(etherReturned >= amount, "no profit");
        depositEther();
    }
    
}