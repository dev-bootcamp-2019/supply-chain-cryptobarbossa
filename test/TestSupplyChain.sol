pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";

contract TestSupplyChain {

  // Initial Ether balance
  uint public initialBalance = 30 ether;

  // Proxy assignments
  SupplyChain public supplyChain;
  Proxy public seller;
  Proxy public buyer;
  Proxy public randomUser;

  // Item configs
  string itemName = "watermelon";
  uint256 itemPrice = 1;
  uint256 itemSku = 0;

  // Incorrect result for items that are not added
  // itemPrice can be re-used but variable below added for clarity
  uint256 fakeItemSku = 600;
  uint256 fakeItemPrice = 5;

  // Mirrored State from SupplyChain
  enum State { 
    ForSale, 
    Sold, 
    Shipped, 
    Received
  }

  // Before each func
  function beforeEach () public {
    supplyChain = new SupplyChain();

    seller = new Proxy(supplyChain);

    buyer = new Proxy(supplyChain);

    randomUser = new Proxy(supplyChain);

    uint256 fund = itemPrice + 1;

    address(buyer).transfer(fund);

    seller.addItem(itemName,itemPrice);
  }

  // Test access modifier with custom function
  function testOnlyOwnerModifier () public {
    bool res = buyer.resolveDispute(itemSku);

    Assert.isFalse(res, "Dispute can only be resolved by owner.");

    bool resOwner = supplyChain.resolveDispute(itemSku);

    Assert.isTrue(resOwner, "Dispute can only be resolved by owner.");
  }

  // Test to check if item is for sale
  function testItemForSale() public {
    string memory _name;
    uint _sku;
    uint _price;
    uint _state;
    address _seller;
    address _buyer;

    (_name, _sku, _price, _state, _seller, _buyer) = supplyChain.fetchItem(itemSku);

    Assert.equal(_name, itemName, "Expected name");
    Assert.equal(_sku, itemSku, "Expected sku");
    Assert.equal(_price, itemPrice, "Expected price");
    Assert.equal(_state, uint(State.ForSale), "Expected state");
    Assert.equal(_buyer, address(0), "Expected buyer = 0x0");
    Assert.equal(_seller, address(seller), "Expected seller");
  }

  // Test to check if user can buy item that is not for sale
  function testBuyItemNotForSale () public {
    bool res = buyer.buyItem(fakeItemSku,fakeItemPrice);

    Assert.isFalse(res, "Item purchase was successfull. Wrong expected result.");
  }

  // Test to check if user can buy item that is for sale
  function testBuyItemForSale () public {
    bool res = buyer.buyItem(itemSku,itemPrice);

    Assert.isTrue(res, "Item purchase failed.");

    string memory _name;
    uint _sku;
    uint _price;
    uint _state;
    address _seller;
    address _buyer;

    (_name, _sku, _price, _state, _seller, _buyer) = supplyChain.fetchItem(itemSku);

    Assert.equal(_state, uint256(State.Sold), "Item has incorrect State. Expected State = Sold ");
  }

  // Test to check if user can buy item with wrong price
  function testBuyItemForSaleWrongPrice () public {
    bool res = buyer.buyItem(itemSku,itemPrice - 1);

    Assert.isFalse(res, "Item purchase succeeded. Not as expected.");

    string memory _name;
    uint _sku;
    uint _price;
    uint _state;
    address _seller;
    address _buyer;

    (_name, _sku, _price, _state, _seller, _buyer) = supplyChain.fetchItem(itemSku);

    Assert.equal(_state, uint256(State.ForSale), "Item has incorrect State. Expected State = ForSale ");
  }

  // Test if item can be shipped
  function testCanShipItem () public {
    bool res = buyer.buyItem(itemSku, itemPrice);
    Assert.isTrue(res, "Failed to purchase item.");

    res = seller.shipItem(itemSku);
    Assert.isTrue(res, "Shipment of item failed.");

    string memory _name;
    uint _sku;
    uint _price;
    uint _state;
    address _seller;
    address _buyer;

    (_name, _sku, _price, _state, _seller, _buyer) = supplyChain.fetchItem(itemSku);

    Assert.equal(_state, uint256(State.Shipped), "Incorrect State. Expected = Shipped");
  }

  // Test if item can be shipped with wrong state
  function testShipItemForSale() public {
    bool res = seller.shipItem(itemSku);
    Assert.isFalse(res, "Item has wrong State and cannot be Shipped.");
    
    string memory _name;
    uint _sku;
    uint _price;
    uint _state;
    address _seller;
    address _buyer;

    (_name, _sku, _price, _state, _seller, _buyer) = supplyChain.fetchItem(itemSku);

    Assert.equal(_state, uint256(State.ForSale), "State is incorrect. Expected = ForSale");
  }

  // Test if item can be received without having been shipped 
  function testNotShippedItemReceived() public {
    bool res = buyer.buyItem(itemSku, itemPrice);
    Assert.isTrue(res, "Purchase failed. Please check price.");

    res = buyer.receiveItem(itemSku);
    Assert.isFalse(res, "Items already sold cannot be received.");

    string memory _name;
    uint _sku;
    uint _price;
    uint _state;
    address _seller;
    address _buyer;

    (_name, _sku, _price, _state, _seller, _buyer) = supplyChain.fetchItem(itemSku);

    Assert.equal(_state, uint256(State.Sold), "Item expected State = Sold");
  }

  // Test to check if buyer has received item
  function testBuyerReceivedItem() public {
    bool res = buyer.buyItem(itemSku, itemPrice);
    Assert.isTrue(res, "Purchase failed. Please check price.");

    res = seller.shipItem(itemSku);
    Assert.isTrue(res, "Seller can ship item that was sold.");

    res = buyer.receiveItem(itemSku);
    
    Assert.isTrue(res, "Buyer should be able to receive item.");

    string memory _name;
    uint _sku;
    uint _price;
    uint _state;
    address _seller;
    address _buyer;

    (_name, _sku, _price, _state, _seller, _buyer) = supplyChain.fetchItem(itemSku);

    Assert.equal(_state, uint256(State.Received), "Item state incorrect. Expected = Received");
  }

  // Test to check if random user can receive items
  function testRandomUserReceiveItem() public {
    bool res = buyer.buyItem(itemSku, itemPrice);
    Assert.isTrue(res, "Purchase failed. Please check price.");

    res = seller.shipItem(itemSku);
    Assert.isTrue(res, "Seller can ship item that was sold.");

    res = randomUser.receiveItem(itemSku);
    
    Assert.isFalse(res, "Random user should not be able to receive item.");

    string memory _name;
    uint _sku;
    uint _price;
    uint _state;
    address _seller;
    address _buyer;

    (_name, _sku, _price, _state, _seller, _buyer) = supplyChain.fetchItem(itemSku);

    Assert.equal(_state, uint256(State.Shipped), "Item state incorrect. Expected = Shipped");
  }

  // Allow this contract to receive ether
  function () public payable {}

}

// Proxy contract
contract Proxy {
  address public target;

  constructor (address _target) public {
    target = _target;
  }

  // Allow contract to receive ether
  function () public payable {}

  function getTarget () public view returns (address) {
    return target;
  }

  function addItem (string _name, uint256 _price) public {
    SupplyChain(target).addItem(_name,_price);
  }

  function buyItem (uint256 _sku, uint256 offer) public returns (bool) {
    return address(target).call.value(offer)(abi.encodeWithSignature("buyItem(uint256)", _sku));
  }

  function shipItem (uint _sku) public returns (bool) {
    return address(target).call(abi.encodeWithSignature("shipItem(uint256)", _sku));
  }

  function receiveItem (uint256 _sku) public returns (bool) {
    return address(target).call(abi.encodeWithSignature("receiveItem(uint256)", _sku));
  }

  function resolveDispute (uint256 _sku) public returns (bool) {
    return address(target).call(abi.encodeWithSignature("resolveDispute(uint256)", _sku));
  }

}