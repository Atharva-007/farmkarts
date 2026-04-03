  Widget _buildWhatsAppMessageInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202C33) : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? Colors.white10 : Colors.grey[300]!),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            GestureDetector(
              onTap: () => _showAttachmentOptions(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.getPrimaryAccent(context).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.attach_file,
                  color: AppTheme.getPrimaryAccent(context),
                  size: 20,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Message input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A3942) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    // Text input
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    
                    // Emoji button
                    GestureDetector(
                      onTap: () => _toggleEmojiPicker(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.emoji_emotions_outlined,
                          color: isDark ? Colors.white60 : AppTheme.primaryGreen,
                          size: 24,
                        ),
                      ),
                    ),
                    
                    // Camera button
                    GestureDetector(
                      onTap: () => _quickCamera(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.camera_alt,
                          color: isDark ? Colors.white60 : AppTheme.primaryGreen,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Send/Record button
            GestureDetector(
              onTap: _isTyping ? _sendMessage : null,
              onLongPressStart: _isTyping ? null : (_) => _startRecording(),
              onLongPressEnd: _isTyping ? null : (_) => _stopRecording(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.getPrimaryAccent(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isTyping 
                      ? Icons.send 
                      : (_isRecording ? Icons.mic : Icons.mic_none),
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedBidCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Positioned(
      left: 16,
      top: 100,
      child: GestureDetector(
        onTap: () => setState(() => _isCardExpanded = !_isCardExpanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _isCardExpanded ? 280 : 200,
          height: _isCardExpanded ? 320 : 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isDark ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.2),
                      isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isCardExpanded 
                      ? _buildExpandedBidCard()
                      : _buildCompactBidCard(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactBidCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.local_offer,
                color: AppTheme.accentOrange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bidding Info',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Tap to expand',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.expand_more,
              color: isDark ? Colors.white60 : Colors.white.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Current highest bid
        if (_currentConversation?.currentHighestBid != null && 
            _currentConversation!.currentHighestBid! > 0) ...[
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.green.shade300,
                size: 16,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Highest Bid',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '₹${_currentConversation!.currentHighestBid!.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.white.withOpacity(0.9),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade300,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'No bids yet',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
        
        const SizedBox(height: 12),
        
        // Total bids count
        Row(
          children: [
            Icon(
              Icons.format_list_numbered,
              color: Colors.orange.shade300,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              '${_currentConversation?.totalBids ?? 0} bids total',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.white.withOpacity(0.8),
                fontSize: 13,
              ),
            ),
          ],
        ),
        
        const Spacer(),
        
        // Quick bid button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _showQuickBidDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange.withOpacity(0.8),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Quick Bid',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedBidCard() {
    final recentBids = _currentConversation?.recentBids ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with close button
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.local_offer,
                color: AppTheme.accentOrange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bidding Details',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _isCardExpanded = false),
              child: Icon(
                Icons.expand_less,
                color: isDark ? Colors.white60 : Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Statistics row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Highest',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    _currentConversation?.currentHighestBid != null && 
                    _currentConversation!.currentHighestBid! > 0
                        ? '₹${_currentConversation!.currentHighestBid!.toStringAsFixed(2)}'
                        : '₹0.00',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Bids',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${_currentConversation?.totalBids ?? 0}',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Recent bids
        if (recentBids.isNotEmpty) ...[
          Text(
            'Recent Bids',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 100,
            child: ListView.builder(
              itemCount: recentBids.take(3).length,
              itemBuilder: (context, index) {
                final bid = recentBids[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getBidStatusIcon(bid.status),
                        color: _getBidStatusColor(bid.status),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${bid.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${bid.quantity} ${bid.unit}',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.white.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatBidTime(bid.createdAt),
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.white.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ] else ...[
          Container(
            height: 100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDark ? Colors.white38 : Colors.white.withOpacity(0.5),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No bids yet',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 12),
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _showQuickBidDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange.withOpacity(0.8),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text(
                  'Quick Bid',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _showDetailedBidDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : Colors.white.withOpacity(0.9),
                  side: BorderSide(
                    color: isDark ? Colors.white30 : Colors.white.withOpacity(0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text(
                  'Detailed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Action methods
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending || _currentConversation == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _chatService.sendEnhancedMessage(
        conversationId: _currentConversation!.id,
        content: content,
        type: MessageType.text,
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ToastHelper.showError(context, 'Failed to send message: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _showAttachmentOptions() async {
    await _mediaService.showMediaPicker(
      context,
      onImageSelected: (file) => _sendMediaFile(file, MessageType.image),
      onVideoSelected: (file) => _sendMediaFile(file, MessageType.video),
      onDocumentSelected: (file) => _sendMediaFile(file, MessageType.document),
    );
  }

  Future<void> _sendMediaFile(File file, MessageType type) async {
    if (_currentConversation == null) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _chatService.sendMediaMessage(
        conversationId: _currentConversation!.id,
        file: file,
        type: type,
        onProgress: (progress) {
          // Update progress if needed
        },
      );

      Navigator.pop(context); // Close loading dialog
      _scrollToBottom();
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ToastHelper.showError(context, 'Failed to send media: $e');
    }
  }

  Future<void> _quickCamera() async {
    // Quick camera functionality
    print('Quick camera pressed');
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });
    // Start voice recording
    print('Recording started');
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    // Stop and send voice recording
    print('Recording stopped');
  }

  Future<void> _showQuickBidDialog() async {
    final TextEditingController bidController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.local_offer, color: AppTheme.accentOrange),
            const SizedBox(width: 8),
            const Text('Quick Bid'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Product: ${_currentConversation?.productName}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'Current Price: ₹${_currentConversation?.productPrice.toStringAsFixed(2)}/${_currentConversation?.productUnit}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bidController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Your Bid Amount',
                prefixText: '₹',
                suffixText: '/${_currentConversation?.productUnit}',
                border: const OutlineInputBorder(),
                hintText: 'Enter amount per ${_currentConversation?.productUnit}',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(bidController.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context);
                _placeBid(amount, 1, _currentConversation?.productUnit ?? 'kg');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Place Bid'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetailedBidDialog() async {
    final TextEditingController bidController = TextEditingController();
    final TextEditingController quantityController = TextEditingController(text: '1');
    final TextEditingController notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.local_offer, color: AppTheme.accentOrange),
            const SizedBox(width: 8),
            const Text('Detailed Bid'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Product: ${_currentConversation?.productName}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bidController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price per ${_currentConversation?.productUnit}',
                  prefixText: '₹',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  suffixText: _currentConversation?.productUnit,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Add any specific requirements or notes...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(bidController.text);
              final quantity = int.tryParse(quantityController.text);
              
              if (amount != null && amount > 0 && quantity != null && quantity > 0) {
                Navigator.pop(context);
                _placeBid(
                  amount,
                  quantity,
                  _currentConversation?.productUnit ?? 'kg',
                  notes: notesController.text.isEmpty ? null : notesController.text,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Place Bid'),
          ),
        ],
      ),
    );
  }

  Future<void> _placeBid(double amount, int quantity, String unit, {String? notes}) async {
    if (_currentConversation == null) return;

    try {
      await _chatService.sendBidOffer(
        conversationId: _currentConversation!.id,
        amount: amount,
        quantity: quantity,
        unit: unit,
        notes: notes,
      );

      ToastHelper.showSuccess(context, 'Bid placed successfully!');
      _scrollToBottom();
    } catch (e) {
      ToastHelper.showError(context, 'Failed to place bid: $e');
    }
  }

  Future<void> _respondToBid(String bidId, BidStatus status) async {
    if (_currentConversation == null) return;

    try {
      await _chatService.respondToBid(
        conversationId: _currentConversation!.id,
        bidId: bidId,
        status: status,
      );

      final statusText = status == BidStatus.accepted ? 'accepted' : 
                       status == BidStatus.rejected ? 'declined' : 'updated';
      ToastHelper.showSuccess(context, 'Bid $statusText successfully!');
    } catch (e) {
      ToastHelper.showError(context, 'Failed to respond to bid: $e');
    }
  }

  Future<void> _initiateCall(CallType callType) async {
    if (_currentConversation == null) return;

    final otherUserId = _currentUser?.uid == _currentConversation!.buyerId
        ? _currentConversation!.sellerId
        : _currentConversation!.buyerId;

    final otherUserName = _currentUser?.uid == _currentConversation!.buyerId
        ? _currentConversation!.sellerName
        : _currentConversation!.buyerName;

    await _mediaService.initiateCall(context, otherUserId, otherUserName, callType);
  }

  void _showMessageOptions(EnhancedChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                // Implement reply functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                // Implement copy functionality
              },
            ),
            if (message.senderId == _currentUser?.uid)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // Implement delete functionality
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showUserProfile() {
    // Show user profile modal
    print('Show user profile');
  }

  void _showDetailedProductInfo() {
    // Show detailed product information
    print('Show product details');
  }

  void _showFullScreenImage(String imageUrl) {
    // Show full screen image viewer
    print('Show full screen image: $imageUrl');
  }

  void _playVideo(String videoUrl) {
    // Play video
    print('Play video: $videoUrl');
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'product_details':
        _showDetailedProductInfo();
        break;
      case 'toggle_bid_card':
        setState(() {
          _showBidCard = !_showBidCard;
        });
        break;
      case 'clear_chat':
        _showClearChatDialog();
        break;
      case 'block_user':
        _showBlockUserDialog();
        break;
    }
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement clear chat functionality
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showBlockUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text('Are you sure you want to block this user? They will no longer be able to contact you.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement block user functionality
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildReplyPreview(String replyToMessageId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: AppTheme.primaryGreen, width: 3)),
      ),
      child: const Text(
        'Reply preview...', // Implement actual reply preview
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // Helper methods for bid card
  IconData _getBidStatusIcon(BidStatus status) {
    switch (status) {
      case BidStatus.accepted:
        return Icons.check_circle;
      case BidStatus.rejected:
        return Icons.cancel;
      case BidStatus.negotiating:
        return Icons.chat;
      case BidStatus.expired:
        return Icons.access_time;
      default:
        return Icons.schedule;
    }
  }

  Color _getBidStatusColor(BidStatus status) {
    switch (status) {
      case BidStatus.accepted:
        return Colors.green;
      case BidStatus.rejected:
        return Colors.red;
      case BidStatus.negotiating:
        return Colors.blue;
      case BidStatus.expired:
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _formatBidTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}