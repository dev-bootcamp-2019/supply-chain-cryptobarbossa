pragma solidity ^0.5.0;

contract SupplyChain {

  /* set owner */
  address public owner;

  /* Add a variable calledå skuCount to track the most recent sku # */
  uint256 public skuCount;

  /* Add a line that creates a public mapping that maps the SKU (a number) to an Item.
     Call this mappings items
  */
  mapping (uint256 => Item) public items;

  /* Add a line that creates an enum called State. This should have 4 states
    ForSale
    Sold
    Shipped
    Received
    (declaring them in this order is important for testing)
  */
  enum State { 
    ForSale, 
    Sold, 
    Shipped, 
    Received
  }

  /* Create a struct named Item.
    Here, add a name, sku, price, state, seller, and buyer
    We've left you to figure out what the appropriate types are,
    if you need help you can ask around :)
  */
  struct Item {
    string name;
    uint256 sku;
    uint256 price;
    State state;
    address payable seller;
    address payable buyer;
  }

  /* Create 4 events with the same name as each possible State (see above)
    Each event should accept one argument, the sku*/
  event ForSale(uint256 indexed sku);
  event Sold(uint256 indexed sku);
  event Shipped(uint256 indexed sku);
  event Received(uint256 indexed sku);
  event DisputeResolved(uint256 indexed sku);

/* Create a modifer that checks if the msg.sender is the owner of the contract */
  modifier onlyOwner {
    require(msg.sender == owner, "Only owner allowed access.");
    _;
  }

  modifier verifyCaller (address _address) {
    require (msg.sender == _address, "Failed to verify caller."); 
    _;
  }

  modifier paidEnough (uint256 _price) {
    require(msg.value >= _price, "Input correct amount."); 
    _;
  }

  modifier checkValue (uint256 _sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    _;
    uint256 _price = items[_sku].price;
    uint256 amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
  }

  modifier checkPriceBoundary (uint256 _price) {
    require(_price > 0 && _price < 2**256-1, "Failed boundary check.");
    _;
  }

  /* For each of the following modifiers, use what you learned about modifiers
   to give them functionality. For example, the forSale modifier should require
   that the item with the given sku has the state ForSale. */
  modifier forSale (uint256 _sku) {
    require(items[_sku].state == State.ForSale, "Expecting State: ForSale");
    _;
  }

  modifier sold (uint256 _sku) {
    require(items[_sku].state == State.Sold, "Expecting State: Sold");
    _;
  }
  modifier shipped (uint256 _sku) {
    require(items[_sku].state == State.Shipped, "Expecting State: Shipped");
    _;
  }
  modifier received (uint256 _sku) {
    require(items[_sku].state == State.Received, "Expecting State: Received");
    _;
  }

  constructor() public {
    /* Here, set the owner as the person who instantiated the contract
       and set your skuCount to 0. */
    owner = msg.sender;
    skuCount = 0;
  }

  /* Mimick example of a dispute between two buyers whom have not finalized their transactions. */
  function resolveDispute (uint256 _sku) public onlyOwner returns (bool) {
    items[_sku].buyer = address(0x0);
    items[_sku].state = State.ForSale;
    emit DisputeResolved(_sku);
    return true;
  }

  function addItem (string memory _name, uint256 _price) public checkPriceBoundary(_price) returns (bool) {
    emit ForSale(skuCount);
    items[skuCount] = Item({name: _name, sku: skuCount, price: _price, state: State.ForSale, seller: msg.sender, buyer: address(0x0)});
    skuCount = skuCount + 1;
    return true;
  }

  /* Add a keyword so the function can be paid. This function should transfer money
    to the seller, set the buyer as the person who called this transaction, and set the state
    to Sold. Be careful, this function should use 3 modifiers to check if the item is for sale,
    if the buyer paid enough, and check the value after the function is called to make sure the buyer is
    refunded any excess ether sent. Remember to call the event associated with this function!*/

  function buyItem (uint256 _sku) public payable forSale(_sku) paidEnough(items[_sku].price) checkValue(_sku) {
    items[_sku].state = State.Sold;
    items[_sku].buyer = msg.sender;
    items[_sku].seller.transfer(items[_sku].price);
    emit Sold(_sku);
  }

  /* Add 2 modifiers to check if the item is sold already, and that the person calling this function
  is the seller. Change the state of the item to shipped. Remember to call the event associated with this function!*/
  function shipItem (uint _sku) public sold(_sku) verifyCaller(items[_sku].seller) {
    items[_sku].state = State.Shipped;
    emit Shipped(_sku);
  }

  /* Add 2 modifiers to check if the item is shipped already, and that the person calling this function
  is the buyer. Change the state of the item to received. Remember to call the event associated with this function!*/
  function receiveItem (uint _sku) public shipped(_sku) verifyCaller(items[_sku].buyer) {
    items[_sku].state = State.Received;
    emit Received(_sku);
  }

  /* We have these functions completed so we can run tests, just ignore it :) */
  function fetchItem (uint _sku) public view returns (string memory name, uint sku, uint price, uint state, address seller, address buyer) {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
  }

}