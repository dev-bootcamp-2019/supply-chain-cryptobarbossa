pragma solidity ^0.4.13;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";

contract TestSupplyChain {

  uint public initialBalance = 15 ether;

  function testAddItemUsingDeployedContract () public {
    SupplyChain supplyChain = SupplyChain(DeployedAddresses.SupplyChain());

    bool expected = true;

    Assert.equal(supplyChain.addItem("car", 5000), expected, "Item should be added");
    Assert.equal(supplyChain.addItem("watch", 1000), expected, "Item should be added");
    Assert.equal(supplyChain.addItem("laptop", 1200), expected, "Item should be added");
    Assert.equal(supplyChain.addItem("candy", 20), expected, "Item should be added");
    Assert.equal(supplyChain.addItem("phone", 2000), expected, "Item should be added");
  }

  function testOnlyOwnerModifier() public {
    SupplyChain supplyChain = new SupplyChain();
    bool expected = true;
    Assert.equal(supplyChain.addItem("car", 5000), expected, "Item should be added");
    Assert.equal(supplyChain.addItem("candy", 20), expected, "Item should be added");
    Assert.equal(supplyChain.resolveDispute(0), expected, "Contract owner only allowed access.");
  }

  function testBuyItemNotForSale () public {
    SupplyChain supplyChain = new SupplyChain();
    ThrowProxy throwProxy = new ThrowProxy(address(supplyChain));

    SupplyChain(address(throwProxy)).buyItem(200);
    bool r = throwProxy.execute.gas(200000)();

    Assert.isFalse(r, "Should be false.");
  }

  function testBuyItemForSale () public {
    SupplyChain supplyChain = new SupplyChain();
    ThrowProxy throwProxy = new ThrowProxy(address(supplyChain));

    supplyChain.addItem("lamp",1);

    SupplyChain(address(throwProxy)).buyItem(0);
    bool r = throwProxy.execute.gas(200000)();

    Assert.equal(r,true, "Should be true.");
  }

    // Test for failing conditions in this contracts
    // test that every modifier is working

    // buyItem

    // test for failure if user does not send enough funds
    // test for purchasing an item that is not for Sale


    // shipItem

    // test for calls that are made by not the seller
    // test for trying to ship an item that is not marked Sold

    // receiveItem

    // test calling the function from an address that is not the buyer
    // test calling the function on an item not marked Shipped

     


}

contract ThrowProxy {
  address public target;
  bytes data;

  constructor (address _target) public {
    target = _target;
  }

  //prime the data using the fallback function.
  function () public {
    data = msg.data;
  }

  function execute() public returns (bool) {
    return target.call(data);
  }
}