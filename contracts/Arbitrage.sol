pragma solidity ^0.5.0;

import "./IUniswapExchange.sol";
import "./IUniswapFactory.sol";
import "./IDutchExchange.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/@gnosis.pm/mock-contract/contracts/MockContract.sol";

/// @title Uniswap Arbitrage Module - Executes arbitrage transactions between Uniswap and DutchX.
/// @author Billy Rennekamp - <billy@gnosis.pm>
contract Arbitrage is Ownable {
    
    uint constant max = uint(-1);

    IUniswapFactory uniFactory;
    IDutchExchange dutchXProxy;

    /// @dev Constructor function sets initial storage of contract.
    /// @param _uniFactory The uniswap factory deployed address.
    /// @param _dutchXProxy The dutchX proxy deployed address.
    constructor(IUniswapFactory _uniFactory, IDutchExchange _dutchXProxy) public {
        uniFactory = _uniFactory;
        dutchXProxy = _dutchXProxy;
    }

    /// @dev Payable fallback function has nothing inside so it won't run out of gas with gas limited transfers
    function() external payable {}

    /// @dev Only owner can deposit contract Ether into the DutchX as WETH
    function depositEther() public payable onlyOwner {

        require(address(this).balance > 0, "Balance must be greater than 0 to deposit");
        uint balance = address(this).balance;

        // Deposit balance to WETH
        address weth = dutchXProxy.ethToken();
        bytes memory payload = abi.encodeWithSignature("deposit()");
        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = weth.call.value(balance).gas(200000)(payload);
        require(success, "Converting Ether to WETH didn't work.");

        // Approve max amount of WETH to be transferred by dutchX
        // Keeping it max will have same or similar costs to making it exact over and over again
        // 200000 was common gas amount added to similar transactions although typically used only ~30k—50k
        // success is not guaranteed by success boolean, returnData deemed unnecessary to decode
        payload = abi.encodeWithSignature("approve(address,uint256)", address(dutchXProxy), max);
        // solium-disable-next-line security/no-call-value
        (success, returnData) = weth.call.value(0).gas(200000)(payload);
        require(success, "Approve WETH to be transferred by DutchX didn't work.");
        require(returnData.length == 0 || (returnData.length == 32 && (returnData[31] != 0)), "Approve WETH to be transferred by DutchX didn't return true.");

        // Deposit new amount on dutchX, confirm there's at least the amount we just deposited
        uint newBalance = dutchXProxy.deposit(weth, balance);
        require(newBalance >= balance, "Deposit WETH to DutchX didn't work.");
    }

    /// @dev Only owner can withdraw WETH from DutchX, convert to Ether and transfer to owner
    /// @param amount The amount of Ether to withdraw
    function withdrawEtherThenTransfer(uint amount) public onlyOwner {
        _withdrawEther(amount);
        address(uint160(owner())).transfer(amount);
    }

    /// @dev Only owner can transfer any Ether currently in the contract to the owner address.
    /// @param amount The amount of Ether to withdraw
    function transferEther(uint amount) public onlyOwner {
        // If amount is zero, deposit the entire contract balance.
        address(uint160(owner())).transfer(amount == 0 ? address(this).balance : amount);
    }

    
    /// @dev Only owner function to withdraw WETH from the DutchX, convert it to Ether and keep it in contract
    /// @param amount The amount of WETH to withdraw and convert.
    function withdrawEther(uint amount) public onlyOwner {
        _withdrawEther(amount);
    }

    /// @dev Internal function to withdraw WETH from the DutchX, convert it to Ether and keep it in contract
    /// @param amount The amount of WETH to withdraw and convert.
    function _withdrawEther(uint amount) internal {

        address weth = dutchXProxy.ethToken();
        dutchXProxy.withdraw(weth, amount);

        // 200000 was common gas amount added to similar transactions although typically used only ~30k—50k
        // success is not guaranteed by success boolean, returnData deemed unnecessary to decode
        bytes memory payload = abi.encodeWithSignature("withdraw(uint256)", amount);
        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = weth.call.value(0).gas(200000)(payload);
        require(success, "Withdraw of Ether from WETH didn't work.");
    }

    /// @dev Only owner can withdraw a token from the DutchX
    /// @param token The token address that is being withdrawn.
    /// @param amount The amount of token to withdraw. Can be larger than available balance and maximum will be withdrawn.
    /// @return Returns the amount actually withdrawn from the DutchX
    function withdrawToken(address token, uint amount) public onlyOwner returns (uint) {
        return dutchXProxy.withdraw(token, amount);
    }

    /// @dev Only owner can transfer tokens to the owner that belong to this contract
    /// @param token The token address that is being transferred.
    /// @param amount The amount of token to transfer.
    function transferToken(address token, uint amount) public onlyOwner {

        // 200000 was common gas amount added to similar transactions although typically used only ~30k—50k
        // success is not guaranteed by success boolean, returnData deemed unnecessary to decode
        bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)", owner(), amount);
        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = token.call.value(0).gas(200000)(payload);
        require(success, "Transfer token didn't work.");
        require(returnData.length == 0 || (returnData.length == 32 && (returnData[31] != 0)), "Transfer token return true.");
    }

    /// @dev Only owner can deposit token to the DutchX
    /// @param token The token address that is being deposited.
    /// @param amount The amount of token to deposit.
    function depositToken(address token, uint amount) public onlyOwner {
        _depositToken(token, amount);
    }

    /// @dev Internal function to deposit token to the DutchX
    /// @param token The token address that is being deposited.
    /// @param amount The amount of token to deposit.
    function _depositToken(address token, uint amount) internal {

        // 200000 was common gas amount added to similar transactions although typically used only ~30k—50k
        // success is not guaranteed by success boolean, returnData deemed unnecessary to decode
        bytes memory payload = abi.encodeWithSignature("approve(address,uint256)", address(dutchXProxy), max);
        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = token.call.value(0).gas(200000)(payload);
        require(success, "Approve token to be transferred by DutchX didn't work.");
        require(returnData.length == 0 || (returnData.length == 32 && (returnData[31] != 0)), "Approve token to be transferred by DutchX didn't return true.");

        // Confirm that the balance of the token on the DutchX is at least how much was deposited
        uint newBalance = dutchXProxy.deposit(token, amount);
        require(newBalance >= amount, "deposit didn't work");
    }

    /// @dev Executes a trade opportunity on dutchX. Assumes that there is a balance of WETH already on the dutchX 
    /// @param arbToken Address of the token that should be arbitraged.
    /// @param amount Amount of Ether to use in arbitrage.
    /// @return Returns if transaction can be executed.
    function dutchOpportunity(address arbToken, uint256 amount) public {

        address etherToken = dutchXProxy.ethToken();

        address uniswapExchange = uniFactory.getExchange(arbToken);

        // The order of parameters for getAuctionIndex don't matter
        uint256 dutchAuctionIndex = dutchXProxy.getAuctionIndex(arbToken, etherToken);

        // postBuyOrder(sellToken, buyToken, amount)
        // results in a decrease of the amount the user owns of the second token
        // which means the buyToken is what the buyer wants to get rid of.
        // "The buy token is what the buyer provides, the seller token is what the seller provides."
        dutchXProxy.postBuyOrder(arbToken, etherToken, dutchAuctionIndex, amount);

        // claimAndWithdrawTokensFromSeveralAuctionsAsBuyers(sellTokens, buyTokens, indexes)
        // This function combines the claimBuyerFunds with the withdraw function.
        // Thought it would be cheaper than using both, but with requirements of so many var declarations it might not be...

        address[] memory arbTokenArray = new address[](1);
        arbTokenArray[0] = arbToken;
        address[] memory etherTokenArray = new address[](1);
        etherTokenArray[0] = etherToken;
        uint[] memory indexArray = new uint[](1);
        indexArray[0] = dutchAuctionIndex;

        // solium-disable-next-line no-unused-vars
        (uint[] memory tokensBought, uint256 magnolia) = dutchXProxy.claimAndWithdrawTokensFromSeveralAuctionsAsBuyer(arbTokenArray, etherTokenArray, indexArray);

        // Approve Uniswap to transfer arbToken on user's behalf
        // Keeping it max will have same or similar costs to making it exact over and over again
        // 200000 was common gas amount added to similar transactions although typically used only ~30k—50k
        // success is not guaranteed by success boolean, returnData deemed unnecessary to decode
        bytes memory payload = abi.encodeWithSignature("approve(address,uint256)", address(uniswapExchange), max);
        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = arbToken.call.value(0).gas(200000)(payload);
        require(success, "Approve arbToken to be transferred by Uniswap didn't work");
        require(returnData.length == 0 || (returnData.length == 32 && (returnData[31] != 0)), "Approve arbToken to be transferred by Uniswap didn't return true");

        // tokenToEthSwapInput(inputToken, minimumReturn, timeToLive)
        // minimumReturn is enough to make a profit (excluding gas)
        // timeToLive is now because transaction is atomic
        uint256 etherReturned = IUniswapExchange(uniswapExchange).tokenToEthSwapInput(tokensBought[0], amount, block.timestamp);

        // gas costs were excluded because worse case scenario the tx fails and gas costs were spent up to here anyway
        // best worst case scenario the profit from the trade alleviates part of the gas costs even if still no total profit
        require(etherReturned >= amount, "no profit");

        // Ether is deposited as WETH
        depositEther();
    }

    /// @dev Executes a trade opportunity on uniswap.
    /// @param arbToken Address of the token that should be arbitraged.
    /// @param amount Amount of Ether to use in arbitrage.
    /// @return Returns if transaction can be executed.
    function uniswapOpportunity(address arbToken, uint256 amount) public {

        // WETH must be converted to Eth for Uniswap trade
        // (Uniswap allows ERC20:ERC20 but most liquidity is on ETH:ERC20 markets)
        _withdrawEther(amount);
        require(address(this).balance >= amount, "buying from uniswap takes real Ether");

        address etherToken = dutchXProxy.ethToken();
        
        // The order of parameters for getAuctionIndex don't matter
        uint256 dutchAuctionIndex = dutchXProxy.getAuctionIndex(arbToken, etherToken);

        // ethToTokenSwapInput(minTokens, deadline)
        // minTokens is 0 because it will revert without a profit regardless
        // deadline is now since trade is atomic
        // solium-disable-next-line security/no-block-members
        uint256 tokensBought = IUniswapExchange(uniFactory.getExchange(arbToken)).ethToTokenSwapInput.value(amount)(0, block.timestamp);
        
        // tokens need to be approved for the dutchX before they are deposited
        _depositToken(arbToken, tokensBought);

        // spend max amount of tokens currently on the dutch x (might be combined from previous remainders)
        // max is automatically reduced to maximum available tokens because there may be
        // token remainders from previous auctions which closed after previous arbitrage opportunities
        dutchXProxy.postBuyOrder(etherToken, arbToken, dutchAuctionIndex, max);
        // solium-disable-next-line no-unused-vars
        (uint etherReturned, uint frtsIssued) = dutchXProxy.claimBuyerFunds(etherToken, arbToken, address(this), dutchAuctionIndex);
        
        // gas costs were excluded because worse case scenario the tx fails and gas costs were spent up to here anyway
        // best worst case scenario the profit from the trade alleviates part of the gas costs even if still no total profit
        require(etherReturned >= amount, "no profit");

        // Ether returned is already in dutchX balance where Ether is assumed to be stored when not being used.
    }
    
}