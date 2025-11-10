// Conversation Management Routes
// Add these routes to your main index.js file

// ============= CONVERSATION MANAGEMENT =============

// Get conversations for user
app.get('/api/conversations', async (req, res) => {
  try {
    const { userId } = req.query;
    
    if (!userId) {
      return res.status(400).json({ success: false, error: 'userId is required' });
    }

    const query = firestore.collection('conversations')
                          .where('participants', 'array-contains', userId)
                          .orderBy('lastMessageTime', 'desc');

    const snapshot = await query.get();
    const conversations = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.json({ success: true, data: conversations });
    logger.info(`Fetched ${conversations.length} conversations for user: ${userId}`);
  } catch (error) {
    logger.error('Error fetching conversations:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Create or get existing conversation
app.post('/api/conversations', async (req, res) => {
  try {
    const { productId, productName, buyerId, buyerName, sellerId, sellerName } = req.body;

    if (!buyerId || !sellerId || !productId) {
      return res.status(400).json({ 
        success: false, 
        error: 'buyerId, sellerId, and productId are required' 
      });
    }

    // Check if conversation already exists
    const existingQuery = await firestore
      .collection('conversations')
      .where('productId', '==', productId)
      .where('participants', '==', [buyerId, sellerId])
      .get();

    if (!existingQuery.empty) {
      const conversation = existingQuery.docs[0];
      return res.json({
        success: true,
        data: { id: conversation.id, ...conversation.data() },
        message: 'Existing conversation found'
      });
    }

    // Create new conversation
    const conversationData = {
      productId,
      productName,
      participants: [buyerId, sellerId],
      buyerId,
      buyerName,
      sellerId,
      sellerName,
      lastMessage: '',
      lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
      lastMessageSenderId: '',
      unreadCount: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'active'
    };

    const docRef = await firestore.collection('conversations').add(conversationData);
    
    res.json({ 
      success: true, 
      data: { id: docRef.id, ...conversationData },
      message: 'New conversation created'
    });

    logger.info(`New conversation created: ${docRef.id} between ${buyerId} and ${sellerId}`);
  } catch (error) {
    logger.error('Error creating conversation:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get messages for conversation
app.get('/api/conversations/:id/messages', async (req, res) => {
  try {
    const { id } = req.params;
    const { limit = 50, page = 1 } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);
    const query = firestore.collection('conversations')
                          .doc(id)
                          .collection('messages')
                          .orderBy('timestamp', 'desc')
                          .limit(parseInt(limit))
                          .offset(offset);

    const snapshot = await query.get();
    const messages = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.json({ 
      success: true, 
      data: messages.reverse(),
      pagination: {
        currentPage: parseInt(page),
        limit: parseInt(limit),
        hasMore: messages.length === parseInt(limit)
      }
    });
  } catch (error) {
    logger.error('Error fetching messages:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Send message
app.post('/api/conversations/:id/messages', async (req, res) => {
  try {
    const { id } = req.params;
    const { senderId, senderName, receiverId, content, type = 'text', attachments = [] } = req.body;

    if (!senderId || !receiverId || !content) {
      return res.status(400).json({ 
        success: false, 
        error: 'senderId, receiverId, and content are required' 
      });
    }

    const messageData = {
      senderId,
      senderName,
      receiverId,
      content,
      type,
      attachments,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
      isDelivered: true
    };

    // Add message to conversation
    const messageRef = await firestore.collection('conversations')
                                   .doc(id)
                                   .collection('messages')
                                   .add(messageData);

    // Update conversation last message
    await firestore.collection('conversations').doc(id).update({
      lastMessage: content.substring(0, 100) + (content.length > 100 ? '...' : ''),
      lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
      lastMessageSenderId: senderId,
      unreadCount: admin.firestore.FieldValue.increment(1)
    });

    // Create notification for receiver
    await firestore.collection('notifications').add({
      userId: receiverId,
      type: 'NEW_MESSAGE',
      title: 'New Message',
      message: `You have a new message from ${senderName}`,
      conversationId: id,
      senderId,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    res.json({ 
      success: true, 
      data: { id: messageRef.id, ...messageData },
      message: 'Message sent successfully'
    });

    logger.info(`Message sent in conversation: ${id} from ${senderId} to ${receiverId}`);
  } catch (error) {
    logger.error('Error sending message:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Mark messages as read
app.put('/api/conversations/:id/messages/read', async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ success: false, error: 'userId is required' });
    }

    // Get all unread messages from other users
    const messagesQuery = await firestore
      .collection('conversations')
      .doc(id)
      .collection('messages')
      .where('receiverId', '==', userId)
      .where('isRead', '==', false)
      .get();

    // Update all messages to read
    const batch = firestore.batch();
    messagesQuery.docs.forEach(doc => {
      batch.update(doc.ref, { 
        isRead: true, 
        readAt: admin.firestore.FieldValue.serverTimestamp() 
      });
    });

    // Reset unread count for this user
    batch.update(firestore.collection('conversations').doc(id), {
      unreadCount: 0
    });

    await batch.commit();

    res.json({ 
      success: true, 
      message: 'Messages marked as read',
      updatedCount: messagesQuery.size
    });

    logger.info(`${messagesQuery.size} messages marked as read in conversation: ${id}`);
  } catch (error) {
    logger.error('Error marking messages as read:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get conversation by product and participants
app.get('/api/conversations/find', async (req, res) => {
  try {
    const { productId, buyerId, sellerId } = req.query;

    if (!productId || !buyerId || !sellerId) {
      return res.status(400).json({ 
        success: false, 
        error: 'productId, buyerId, and sellerId are required' 
      });
    }

    const query = await firestore
      .collection('conversations')
      .where('productId', '==', productId)
      .where('participants', 'array-contains-any', [buyerId, sellerId])
      .get();

    // Find conversation that contains both participants
    const conversation = query.docs.find(doc => {
      const data = doc.data();
      return data.participants.includes(buyerId) && data.participants.includes(sellerId);
    });

    if (conversation) {
      res.json({ 
        success: true, 
        data: { id: conversation.id, ...conversation.data() }
      });
    } else {
      res.status(404).json({ 
        success: false, 
        error: 'Conversation not found' 
      });
    }
  } catch (error) {
    logger.error('Error finding conversation:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Delete conversation (archive)
app.delete('/api/conversations/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ success: false, error: 'userId is required' });
    }

    // Instead of deleting, mark as archived for the user
    await firestore.collection('conversations').doc(id).update({
      [`archivedBy.${userId}`]: true,
      [`archivedAt.${userId}`]: admin.firestore.FieldValue.serverTimestamp()
    });

    res.json({ 
      success: true, 
      message: 'Conversation archived successfully'
    });

    logger.info(`Conversation archived: ${id} by user: ${userId}`);
  } catch (error) {
    logger.error('Error archiving conversation:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});