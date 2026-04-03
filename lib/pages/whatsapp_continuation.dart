  
  Widget _buildEnhancedMessageBubble(EnhancedChatMessage message, bool isMe) {
    switch (message.type) {
      case MessageType.bid:
        return _buildBidMessageBubble(message, isMe);
      case MessageType.image:
        return _buildImageMessageBubble(message, isMe);
      case MessageType.video:
        return _buildVideoMessageBubble(message, isMe);
      case MessageType.audio:
        return _buildAudioMessageBubble(message, isMe);
      case MessageType.document:
        return _buildDocumentMessageBubble(message, isMe);
      case MessageType.location:
        return _buildLocationMessageBubble(message, isMe);
      case MessageType.call:
        return _buildCallMessageBubble(message, isMe);
      case MessageType.system:
        return _buildSystemMessageBubble(message);
      default:
        return _buildTextMessageBubble(message, isMe);
    }
  }

  Widget _buildTextMessageBubble(EnhancedChatMessage message, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.getPrimaryAccent(context),
              backgroundImage: message.senderAvatar.isNotEmpty
                  ? CachedNetworkImageProvider(message.senderAvatar)
                  : null,
              child: message.senderAvatar.isEmpty
                  ? Text(
                      message.senderName.isNotEmpty 
                          ? message.senderName[0].toUpperCase() 
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 
                            (_showBidCard ? 0.55 : 0.7),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isMe 
                      ? (isDark ? const Color(0xFF054740) : const Color(0xFFDCF8C6)) 
                      : (isDark ? const Color(0xFF202C33) : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.replyToMessageId != null)
                      _buildReplyPreview(message.replyToMessageId!),
                    
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _formatMessageTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          _buildMessageStatusIcon(message.status, isDark ? Colors.white60 : null),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          if (isMe) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildBidMessageBubble(EnhancedChatMessage message, bool isMe) {
    final bidOffer = message.bidOffer!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.accentOrange,
              child: const Icon(Icons.local_offer, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 
                            (_showBidCard ? 0.6 : 0.75),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isMe 
                        ? [AppTheme.accentOrange, AppTheme.accentOrange.withOpacity(0.8)]
                        : [
                            isDark ? const Color(0xFF3D2B1F) : Colors.orange[50]!, 
                            isDark ? const Color(0xFF2D1B0F) : Colors.orange[100]!
                          ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  border: Border.all(
                    color: AppTheme.accentOrange.withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentOrange.withOpacity(isDark ? 0.1 : 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bid header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            isMe ? 'Your Bid Offer' : 'Bid Offer Received',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          _buildBidStatusChip(bidOffer.status),
                        ],
                      ),
                    ),
                    
                    // Bid content
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price and quantity
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Price per ${bidOffer.unit}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    '₹${bidOffer.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Quantity',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    '${bidOffer.quantity} ${bidOffer.unit}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Total amount
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                Text(
                                  '₹${bidOffer.totalAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.orange[300] : AppTheme.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Notes
                          if (bidOffer.notes?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Notes:',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              bidOffer.notes!,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                          
                          // Validity
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: bidOffer.isExpired ? Colors.red : (isDark ? Colors.green[300] : Colors.green),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                bidOffer.isExpired 
                                    ? 'Expired' 
                                    : 'Valid until ${_formatDate(bidOffer.validUntil)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: bidOffer.isExpired ? Colors.red : (isDark ? Colors.green[300] : Colors.green),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          
                          // Action buttons (for received bids)
                          if (!isMe && bidOffer.status == BidStatus.pending && !bidOffer.isExpired) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _respondToBid(
                                      bidOffer.id,
                                      BidStatus.accepted,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Accept', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _respondToBid(
                                      bidOffer.id,
                                      BidStatus.rejected,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    icon: const Icon(Icons.close, size: 16),
                                    label: const Text('Decline', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _respondToBid(
                                      bidOffer.id,
                                      BidStatus.negotiating,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.accentOrange,
                                      side: BorderSide(color: AppTheme.accentOrange),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    icon: const Icon(Icons.chat, size: 16),
                                    label: const Text('Counter', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          
                          const SizedBox(height: 8),
                          
                          // Message timestamp and status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                _formatMessageTime(message.timestamp),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : Colors.grey[600],
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                _buildMessageStatusIcon(message.status, isDark ? Colors.white60 : null),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          if (isMe) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildCallMessageBubble(EnhancedChatMessage message, bool isMe) {
    final callInfo = message.callInfo!;
    final isVideoCall = callInfo.type == CallType.video;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 40),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF202C33) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: isDark ? Border.all(color: Colors.white10) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isVideoCall ? Icons.videocam : Icons.call,
                size: 20,
                color: callInfo.status == CallStatus.missed ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVideoCall ? 'Video Call' : 'Voice Call',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    _getCallStatusText(callInfo, isMe),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (callInfo.duration != null) ...[
                const SizedBox(width: 12),
                Text(
                  _formatDuration(callInfo.duration!),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemMessageBubble(EnhancedChatMessage message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.yellow[900]!.withOpacity(0.2) : Colors.yellow[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.yellow[100] : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<List<TypingIndicator>>(
      stream: _chatService.getTypingIndicators(_currentConversation!.id),
      builder: (context, snapshot) {
        final indicators = snapshot.data ?? [];
        
        if (indicators.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppTheme.getPrimaryAccent(context),
                child: Text(
                  indicators.first.userName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedBuilder(
                animation: _typingAnimation,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF202C33) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTypingDot(0),
                        const SizedBox(width: 4),
                        _buildTypingDot(1),
                        const SizedBox(width: 4),
                        _buildTypingDot(2),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
