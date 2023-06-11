// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract CryptoShop {
    // Order Statuses
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

    string[] public productCategories;

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

    // Order Item Structure
    struct Cart {
        mapping(address => uint256[])  _cart_item_ids;
        mapping(address => uint256[])  _cart_item_qtys;
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

    constructor() {
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
    function addToCart(
        uint256  cartItemId,
        uint256  cartItemQty
    ) public {
        
        // Validate Product
        require(
            cartItemId <= products.length &&
            cartItemQty > 0,
            "Invalid input"
        );

        // Validate Quantity
        uint256 availableQty = products[cartItemId - 1]._product_quantities;
        require(
            availableQty >= cartItemQty,
            "Invalid item quantity"
        );

        bool IsItemExists = false;

        if(my_cart._cart_item_ids[msg.sender].length > 0){
            uint256[] memory arr = new uint256[](my_cart._cart_item_ids[msg.sender].length);
            
            for (uint256 i = 0; i < (my_cart._cart_item_ids[msg.sender].length); i++) {
                arr[i] = uint256(my_cart._cart_item_ids[msg.sender][i]);
            }

            // Check item is already exists in the cart
            if( in_array(cartItemId, arr)){
                // update item qty
                IsItemExists = true;
            }
        }

        if(IsItemExists == false){
            // add new item into cart
            my_cart._cart_item_ids[msg.sender].push(cartItemId);
            my_cart._cart_item_qtys[msg.sender].push(cartItemQty);
        }

        
    }

    /**
    * ==========================================================================
    * GET CART
    * ==========================================================================
    * access : any
    *
    */
    function getCartItems() public view returns (uint256[] memory, uint256[] memory) {
        return (
                my_cart._cart_item_ids[msg.sender],  // ids
                my_cart._cart_item_qtys[msg.sender]  // qtys
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
     * CREATE ORDER
     */
    function createOrder(
        uint256 final_total,
        string memory billing_address,
        string memory shipping_address,
        uint256[] memory productIds,
        uint256[] memory productQtys,
        uint256[] memory productPrices
    ) public payable {
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

        require(grandTotal == final_total, "Final total mismatched.");

        uint requiredAmt = 1;
        require(msg.value >= requiredAmt, "Insufficient payment");

        payTo(owner,requiredAmt);
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


    function getBalance(address _address) public view returns (uint256) {
        return _address.balance;
    }

    function payTo(
        address to, 
        uint256 amount
    ) internal returns (bool) {
        (bool success,) = payable(to).call{value: amount}("");
        require(success, "Payment failed.");
        return true;
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
        returns (bool)
    {
        for (uint256 i = 0; i < haystack.length; i++) {
            if (haystack[i] == needle) {
                return true;
            }
        }
        return false;
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
