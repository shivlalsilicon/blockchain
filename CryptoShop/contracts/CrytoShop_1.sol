// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "hardhat/console.sol";

contract CryptoShop {
    // ENUM : Order Statuses
    enum OrderStatus {
        Pending,
        Processing,
        Completed,
        Cancelled,
        Failed,
        Onhold,
        Refunded,
        Deleted
    }

    // ENUM : Coupon Types
    enum CouponTypes {
        FixedCartDiscount,
        FixedProductDiscount,
        PercentageDiscount
    }

    // Product Structure
    struct Product {
        uint256 _product_id;
        string _product_title;
        string _product_description;
        uint256 _product_quantities;
        uint256 _product_price;
        uint256 _product_publish_date;
        uint256 _product_updated_date;
        uint256 _product_status;
    }

    /**
     * ==========================================================================
     * Coupon Structure
     * ==========================================================================
     * _type : Discount type (Fixed Cart Discount, Fixed Product Discount, Percentage Discount).
     * _amount : Value of the coupon.
     * _expirty_date : The coupon will expire at 00:00:00 of this date.
     * _minimum_spend : This field allows you to set the minimum spend (subtotal) allowed to use the coupon.
     * _maximum_spend : This field allows you to set the maximum spend (subtotal) allowed when using the coupon.
     * _products : Products that the coupon will be applied to, or that need to be in the cart in order for the "Fixed cart discount" to be applied.
     * _usage_coupon_limit : How many times this coupon can be used before it is void.
     * _usage_user_limit : How many times this coupon can be used by an individual user. Uses billing email for guests, and user ID for logged in users.
     *
     */

    struct Coupon {
        string _type;
        uint256 _amount;
        string _expirty_date;
        uint256 _minimum_spend;
        uint256 _maximum_spend;
        uint256[] _products;
        uint256 _usage_coupon_limit;
        uint256 _usage_user_limit;
    }

    // Order Item Structure
    struct Cart {
        mapping(address => uint256[]) _cart_item_ids;
        mapping(address => uint256[]) _cart_item_qtys;
        mapping(address => uint256[]) _cart_item_prices;
       // mapping(address => uint256) _total;
        
    }

    // Order Item Structure
    struct orderItem {
        uint256 _item_id;
        uint256 _item_qty;
    }

    // Order Structure
    struct Order {
        uint256 _order_id;
        address _customer;
        uint256 _date_of_purchase;
        OrderStatus _status;
        string _billing_address;
        string _shipping_address;
        uint256 _purchase_total;
        uint256[] _ord_item_ids;
        uint256[] _ord_item_qty;
        uint256[] _ord_item_prices;
    }

    // Used In Heler Method - array_search
    struct ArraySearch {
        bool found;
        uint256 key;
    }

    orderItem[] private orderitems;
    Product[] private products;
    Cart private my_cart;

    //mapping(address => Cart[]) private my_cart;
    mapping(address => Order[]) private orders;
    uint256 private _OrderID = 0;
    uint256 private _ProductID = 0;
    uint256 private _CartID = 0;
    address private owner;
    string[] public productCategories;
    mapping(address => uint256) balances;

    /**
     * ==========================================================================
     * Construcor
     * ==========================================================================
     * balance, owner,
     *
     */
    constructor() {
        balances[msg.sender] = 10000;
        owner = msg.sender;

        productCategories = [
            "smartphones",
            "laptops",
            "fragrances",
            "skincare",
            "groceries",
            "home-decoration",
            "furniture",
            "tops",
            "womens-dresses",
            "womens-shoes",
            "mens-shirts",
            "mens-shoes",
            "mens-watches",
            "womens-watches",
            "womens-bags",
            "womens-jewellery",
            "sunglasses",
            "automotive",
            "motorcycle",
            "lighting"
        ];
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    /**
     * ==========================================================================
     * ADD TO CART
     * ==========================================================================
     * access : any
     *
     */
    function addToCart(uint256 cartItemId, uint256 cartItemQty) public {
        // Validate Product
        require(
            cartItemId <= products.length && cartItemQty > 0,
            "Invalid input"
        );

        // Validate Quantity
        uint256 availableQty = products[cartItemId - 1]._product_quantities;
        require(availableQty >= cartItemQty, "Invalid item quantity");

        uint256 productPrice = products[cartItemId - 1]._product_price;

        bool IsItemExists = false;

        if (my_cart._cart_item_ids[msg.sender].length > 0) {
            uint256[] memory arr = new uint256[](
                my_cart._cart_item_ids[msg.sender].length
            );

            

            for (
                uint256 i = 0;
                i < (my_cart._cart_item_ids[msg.sender].length);
                i++
            ) {
                arr[i] = uint256(my_cart._cart_item_ids[msg.sender][i]);
            }

            // Check item is already exists in the cart
            uint256 CartIndex = in_array(cartItemId, arr);
            if (CartIndex != 0) {
                // update item qty
                IsItemExists = true;
                uint256 PreviousQty = my_cart._cart_item_qtys[msg.sender][
                    CartIndex - 1
                ];
                my_cart._cart_item_qtys[msg.sender][CartIndex - 1] =
                    PreviousQty +
                    cartItemQty;
            }
        }

        if (IsItemExists == false) {
            // add new item into cart
            my_cart._cart_item_ids[msg.sender].push(cartItemId);
            my_cart._cart_item_qtys[msg.sender].push(cartItemQty);
            my_cart._cart_item_prices[msg.sender].push(productPrice);
        }
    }

    /**
     * ==========================================================================
     * GET CART
     * ==========================================================================
     * access : any
     *
     */
    function getCartItems()
        public
        view
        returns (uint256[] memory, uint256[] memory, uint256[] memory,uint256 total)
    {
        uint256 grandTotal = 0;
        if (my_cart._cart_item_ids[msg.sender].length > 0) {
          for (uint256 i = 0; i < my_cart._cart_item_ids[msg.sender].length; i++) {
              grandTotal+= my_cart._cart_item_prices[msg.sender][i] * my_cart._cart_item_qtys[msg.sender][i];
          }  
        }

        return (
            my_cart._cart_item_ids[msg.sender],
            my_cart._cart_item_qtys[msg.sender],
            my_cart._cart_item_prices[msg.sender],
            grandTotal
        );
    }

    

    /**
     * ==========================================================================
     * ADD NEW PRODUCT
     * ==========================================================================
     * access : owner
     *
     */
    function addProduct(
        string memory ProductTitle,
        string memory ProductDesc,
        uint256 ProductQuantities,
        uint256 ProductPrice
    ) public onlyOwner {
        require(ProductQuantities > 0 && ProductPrice > 0, "Invalid Input");

        //Generate ID
        _ProductID++;

        Product memory newProduct = Product({
            _product_id: _ProductID,
            _product_title: ProductTitle,
            _product_description: ProductDesc,
            _product_quantities: ProductQuantities,
            _product_price: ProductPrice,
            _product_publish_date: block.timestamp,
            _product_updated_date: 0,
            _product_status: 1
        });

        products.push(newProduct);
    }

    /**
     * GET PRODUCTS
     */
    function getProducts() public view returns (Product[] memory) {
        return products;
    }

    /**
     * ==========================================================================
     * DELETE PRODUCT
     * ==========================================================================
     * access : Owner
     *
     */
    function deleteProduct(uint256 productId) public onlyOwner {
        require(productId <= products.length, "Invalid product ID");
        products[productId - 1]._product_status = 0;
    }

    /**
     * ==========================================================================
     * UPDATE PRODUCT
     * ==========================================================================
     * access : Owner
     *
     */
    function updateProduct(
        uint256 productId,
        string memory ProductTitle,
        string memory ProductDesc,
        uint256 ProductQuantities,
        uint256 ProductPrice
    ) public onlyOwner {
        require(
            productId <= products.length &&
                ProductQuantities > 0 &&
                ProductPrice > 0,
            "Invalid Input"
        );

        products[productId - 1]._product_title = ProductTitle;
        products[productId - 1]._product_description = ProductDesc;
        products[productId - 1]._product_quantities = ProductQuantities;
        products[productId - 1]._product_price = ProductPrice;
        products[productId - 1]._product_publish_date = block.timestamp;
    }

    /**
     * ==========================================================================
     * GET SINGLE PRODUCT BY ID
     * ==========================================================================
     * access : any
     *
     */
    function getProduct(uint256 productId)
        public
        view
        returns (Product memory)
    {
        require(
            productId > 0 && productId <= products.length,
            "Invalid product ID"
        );
        return products[productId - 1];
    }

    /**
     * ==========================================================================
     * Create Order
     * ==========================================================================
     * access : private
     *
     */
    function createOrder_bkp_14062023(
        uint256 final_total,
        string memory billing_address,
        string memory shipping_address,
        uint256[] memory productIds,
        uint256[] memory productQtys,
        uint256[] memory productPrices
    ) internal  {
        require(
            productIds.length == productQtys.length &&
                productIds.length == productPrices.length,
            "Invalid input arrays"
        );

        uint256 grandTotal = 0;

        // Check product availability and deduct quantities
        for (uint256 i = 0; i < productIds.length; i++) {
            require(productIds[i] <= products.length, "Invalid product ID");
            uint256 productId = productIds[i];
            uint256 requestedQty = productQtys[i];
            uint256 requestedItemPrice = productPrices[i];

            // #Using pointer storage location (call by ref.)
            /*
            Product storage product = products[productId - 1];
            // --- Product memory product = products[productId - 1];
            uint256 actualItemPrice = product._product_price;
            require(actualItemPrice == requestedItemPrice, "Invalid product price");
            
            uint256 availableQty = product._product_quantities;
            require(availableQty >= requestedQty, "Insufficient product quantity");
            
            product._product_quantities = availableQty - requestedQty;
            */

            uint256 actualItemPrice = products[productId - 1]._product_price;
            require(
                actualItemPrice == requestedItemPrice,
                "Invalid product price"
            );

            uint256 availableQty = products[productId - 1]._product_quantities;
            require(
                availableQty >= requestedQty,
                "Insufficient product quantity"
            );

            products[productId - 1]._product_quantities =
                availableQty -
                requestedQty;

            grandTotal += requestedQty * productPrices[i];
        }

        // require(grandTotal == final_total, "Final total mismatched.");

       // uint256 requiredAmt = 1;
        //  require(msg.value >= requiredAmt, "Insufficient payment");

      
        //Generate Order ID
        _OrderID++;

        // Insert Order
        Order memory newOrder = Order({
            _order_id: _OrderID,
            _customer: msg.sender,
            _date_of_purchase: block.timestamp,
            _status: OrderStatus.Pending,
            _billing_address: billing_address,
            _shipping_address: shipping_address,
            _purchase_total: final_total,
            _ord_item_ids: productIds,
            _ord_item_qty: productQtys,
            _ord_item_prices: productPrices
        });

        orders[msg.sender].push(newOrder);
    }

    function _createOrder(
        string memory billing_address,
        string memory shipping_address,
        uint256[] memory productIds,
        uint256[] memory productQtys,
        uint256[] memory productPrices
    ) private  returns (Order memory newOrder) {
        require(
            productIds.length == productQtys.length &&
                productIds.length == productPrices.length,
            "Invalid input arrays"
        );

        uint256 grandTotal = 0;

        // Check product availability and deduct quantities
        for (uint256 i = 0; i < productIds.length; i++) {
            require(productIds[i] <= products.length, "Invalid product ID");
            uint256 productId = productIds[i];
            uint256 requestedQty = productQtys[i];
            uint256 requestedItemPrice = productPrices[i];

            uint256 actualItemPrice = products[productId - 1]._product_price;
            require(
                actualItemPrice == requestedItemPrice,
                "Invalid product price"
            );

            uint256 availableQty = products[productId - 1]._product_quantities;
            require(
                availableQty >= requestedQty,
                "Insufficient product quantity"
            );

            products[productId - 1]._product_quantities =
                availableQty -
                requestedQty;

            grandTotal += requestedQty * productPrices[i];
        }

        uint256 requiredAmt = 1;
        requiredAmt;
        //  require(msg.value >= requiredAmt, "Insufficient payment");

        //payTo(owner,requiredAmt);
        //Generate Order ID
        _OrderID++;

        // Insert Order
        return Order({
            _order_id: _OrderID,
            _customer: msg.sender,
            _date_of_purchase: block.timestamp,
            _status: OrderStatus.Pending,
            _billing_address: billing_address,
            _shipping_address: shipping_address,
            _purchase_total: grandTotal,
            _ord_item_ids: productIds,
            _ord_item_qty: productQtys,
            _ord_item_prices: productPrices
        });

        //return newOrder;
       // orders[msg.sender].push(newOrder);

        //return _OrderID;
    }

    function placeOrder(
        string memory shipping_address, 
        string memory billing_address
    ) public payable  returns (uint256 OrderID) {

        uint256[] memory CartItemIds;
        uint256[] memory CartQtys;
        uint256[] memory CartPrices;
        uint256 CartTotal;
        
        (CartItemIds,CartQtys,CartPrices,CartTotal) = getCartItems();

        require(CartItemIds.length  > 0, "Cart is empty");

        require(
            CartItemIds.length == CartQtys.length,
            "Invalid input arrays"
        );

        require( bytes(billing_address).length > 0, "Billing address can not be blank.");
        require( bytes(shipping_address).length > 0, "Shipping address can not be blank.");
        Order memory newOrder =  _createOrder(billing_address, shipping_address, CartItemIds, CartQtys, CartPrices);

        uint256 requiredAmt = 1 ether;

        // proceed to pay
        (bool success, ) = payable(owner).call{value: requiredAmt}("");
        require(success, "Payment failed.");



        // Assign Order to Customer after Payment Success
        orders[msg.sender].push(newOrder);
        
        // Blank cart after payment
        delete my_cart._cart_item_ids[msg.sender];
        delete my_cart._cart_item_qtys[msg.sender];
        delete my_cart._cart_item_prices[msg.sender];
        
        return newOrder._order_id;
     

    }



    /**
     * CREATE ORDER
     */
    function getOrders(address user) public view returns (Order[] memory) {
        return orders[user];
    }

    /**
     * ==========================================================================
     * GET ALL ORDERS
     * ==========================================================================
     * access: owner
     *
     */
    function getAllOrders() public view onlyOwner returns (Order[] memory) {
        uint256 totalOrders;
        for (uint256 i = 0; i < orders[msg.sender].length; i++) {
            totalOrders += orders[msg.sender][i]._customer == msg.sender
                ? 1
                : 0;
        }

        Order[] memory allOrders = new Order[](totalOrders);
        uint256 orderIndex = 0;

        for (uint256 i = 0; i < orders[msg.sender].length; i++) {
            if (orders[msg.sender][i]._customer == msg.sender) {
                allOrders[orderIndex] = orders[msg.sender][i];
                orderIndex++;
            }
        }

        return allOrders;
    }

    /**
     * ==========================================================================
     * UPDATE ORDER STATUS
     * ==========================================================================
     * access: owner
     *
     *  # Order Statuses -
     *  0 = Pending,
     *  1 = Processing,
     *  2 = Completed,
     *  3 = Cancelled,
     *  4 = Failed,
     *  5 = Onhold,
     *  6 = Refunded
     *  7 = Deleted
     *
     */
    function updateOrderStatus(uint256 orderId, OrderStatus status)
        public
        onlyOwner
    {
        require(orderId <= orders[msg.sender].length, "Invalid order ID");
        orders[msg.sender][orderId - 1]._status = status;
    }

    /**
     * ==========================================================================
     * GET ORDER STATUS BY _ORDER_ID_
     * ==========================================================================
     * access : any
     *
     */
    function getOrderStatus(uint256 orderId)
        public
        view
        onlyOwner
        returns (string memory)
    {
        require(orderId <= orders[msg.sender].length, "Invalid order ID");

        OrderStatus status = orders[msg.sender][orderId - 1]._status;

        if (status == OrderStatus.Pending) {
            return "Pending";
        } else if (status == OrderStatus.Processing) {
            return "Processing";
        } else if (status == OrderStatus.Completed) {
            return "Completed";
        } else if (status == OrderStatus.Cancelled) {
            return "Cancelled";
        } else if (status == OrderStatus.Failed) {
            return "Failed";
        } else if (status == OrderStatus.Onhold) {
            return "On-Hold";
        } else if (status == OrderStatus.Refunded) {
            return "Refunded";
        } else {
            revert("Invalid order status");
        }
    }

    /**
     * ==========================================================================
     * GET SINGLE ORDER BY _ORDER_ID_
     * ==========================================================================
     * access : any
     *
     */
    function getOrder(uint256 orderId) public view returns (Order memory) {
        require(
            orderId > 0 && orderId <= orders[msg.sender].length,
            "Invalid order ID"
        );
        return orders[msg.sender][orderId - 1];
    }

    /**
     * ==========================================================================
     * HELPERS
     * ==========================================================================
     */

    /**
     * Helper
     *
     * Checks if a value exists in an array
     *
     * @param needle The searched value.
     * @param haystack array of int values.
     *
     */
    function in_array(uint256 needle, uint256[] memory haystack)
        internal
        pure
        returns (uint256 rtn)
    {
        for (uint256 i = 0; i < haystack.length; i++) {
            if (haystack[i] == needle) {
                // return true;

                return uint256(i + 1);
            }
        }
        // return false;
        return 0;
    }

    /**
     * Helper
     *
     * Searches the array for a given value and returns the first corresponding key if successful
     *
     * @param needle The searched value.
     * @param haystack array of int values.
     *
     * @return Returns the key for needle if it is found in the array, false otherwise.
     */
    function array_search(uint256 needle, uint256[] memory haystack)
        internal
        pure
        returns (ArraySearch memory)
    {
        ArraySearch memory result;
        bool found = false;
        uint256 indexValue;
        for (uint256 i = 0; i < haystack.length; i++) {
            if (haystack[i] == needle) {
                found = true;
                indexValue = i;
            }
        }

        result.found = found;
        result.key = indexValue;
        return result;
    }
}
