// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NftMarketPlace is ERC1155 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    enum OrderTypes{
        _owner,
        _transfer
    }

    // Fee/Commision Structure
    struct Fee{
        uint256 _publishable_charges_qty; //  number of product qty amount 
        uint256 _product_owner_commission; // Commision to owner (In %)
        uint256 _selling_price_increment; // Increment On Current Cost Price When Transter Token (in %)
    }

    // Product Structure
    struct Product {
        uint256 _product_id;
        string _title;
        string _image_url;
        string _description;
        uint256 _quantities;
        uint256 _selling_price;
        address _verdor;
    }

    // Order Structure
    struct Order {
        uint256 _order_id;
        OrderTypes _type;
        uint256 _product_id;
        uint256 _qty;
        uint256 _total;
        uint256 _current_qty;
        uint256 _cost_price;
        uint256 _selling_price;
        uint256 _token;
        address _customer;
        uint256 _order_datetime;
    }

    uint256 private _OrderID = 0;
    uint256 private _ProductID = 0;
    address private owner;

    Product[] private products;
    Order[] private orders;
    Fee private _fee;

   // mapping(address => Product[]) private products;

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    event ProductPurchased(uint256 indexed productId, address indexed buyer);


    constructor()  ERC1155("https://game.example/api/item/{id}.json") {
        owner = msg.sender;

        // Setup Commission and Fee
        _fee._publishable_charges_qty = 1; // qty amount
        _fee._product_owner_commission = 2; // percent
        _fee._selling_price_increment = 10; // percent
    }

    // Add Product Fn
    function addProduct(
        string memory ProductTitle,
        string memory ProductDesc,
        string memory ProductImageUrl,
        uint256 ProductQuantities,
        uint256 ProductPrice
    )  public  {

        require(ProductQuantities > 0 && ProductPrice > 0, "Invalid Input");
        _ProductID++;
        Product memory newProduct = Product({
            _product_id: _ProductID,
            _title: ProductTitle,
            _image_url: ProductImageUrl,
            _description: ProductDesc,
            _quantities: ProductQuantities,
            _selling_price: ProductPrice,
            _verdor: msg.sender
        });

        /**
        *    Pay 1 Qty Product Amt to Contract Owner....
        **/
     
        // proceed to pay
        // (bool success ) = payable(owner).call{value: ProductPrice}("");
        // require(success, "Payment failed.");

        products.push(newProduct);
    }

    function Purchase(
        uint256 ProductID,
        uint256 ProductQty
    ) public payable {

        require(
            ProductID  > 0 &&
            ProductQty > 0,
            "Invalid input"
        );
        
        uint256 availableQty = products[ProductID - 1]._quantities;

        require(
            availableQty >= ProductQty,
            "Invalid item quantity"
        );

        uint256 productPrice = products[ProductID - 1]._selling_price;
        uint256 payableAmount = productPrice * ProductQty;
        address vendor =  products[ProductID - 1]._verdor;
        
        require(
            msg.value == payableAmount,
            "Insufficient Fund."
        );

        payable(vendor).transfer(payableAmount);

        //Mint
        uint256 _token_number = _mint_product( msg.sender, ProductQty);

        // Calculate Selling Price
        uint256 sellingPrice =  (productPrice/_fee._selling_price_increment)+productPrice;

        _OrderID++;
        Order memory order = Order({
            _order_id : _OrderID,
            _type : OrderTypes._owner,
            _product_id : ProductID,
            _qty : ProductQty,
            _total : payableAmount,
            _current_qty : ProductQty,
            _cost_price : productPrice,
            _selling_price : sellingPrice,
            _token : _token_number,
            _customer :  msg.sender,
            _order_datetime : block.timestamp
        });

        orders.push(order);

        // Update Product Qty
        products[ProductID - 1]._quantities = availableQty - ProductQty;

        emit ProductPurchased(ProductID, msg.sender);
    }

    function _mint_product(address to, uint256 qty)
        private returns (uint256 _token){
            
            _tokenIdCounter.increment();
            _mint(to, _tokenIdCounter.current(), qty, "");

            return  _tokenIdCounter.current();
    }

    function ger_orders() public view returns (Order[] memory ords){
        return orders;
    }

    function ger_products() public view returns (Product[] memory items){
        return products;
    }


}