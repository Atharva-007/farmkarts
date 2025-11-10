"""
Enhanced Agricultural Knowledge Corpus for RAG System
Comprehensive Indian farming knowledge with advanced techniques
"""

import asyncio
import json
from typing import List, Dict, Any
from rag_pipeline import RAGPipeline
from embeddings import EmbeddingService
from generator import ResponseGenerator
from index_store import IndexStore
import logging

logger = logging.getLogger(__name__)

class EnhancedKnowledgeBuilder:
    """Build comprehensive agricultural knowledge base"""
    
    def __init__(self, rag_pipeline: RAGPipeline):
        self.rag_pipeline = rag_pipeline
        
    async def add_advanced_crop_knowledge(self):
        """Add comprehensive crop-specific knowledge"""
        
        advanced_docs = [
            {
                "content": """
                Advanced Vegetable Production Systems - Protected Cultivation and Precision Farming
                
                Protected cultivation of vegetables represents the future of Indian horticulture with potential for 3-5x higher yields compared to open field cultivation.
                
                **Polyhouse/Greenhouse Technology for Indian Conditions:**
                
                Structure Design for Indian Climate:
                • Naturally Ventilated Polyhouses (NVPH): Cost-effective for Indian conditions
                • Climate-Controlled Greenhouses: For high-value crops and export quality
                • Shade Net Houses: 35-75% shade for different vegetable requirements
                • Walk-in Tunnels: Low-cost protection for small farmers
                
                Optimal Specifications:
                • Height: 3.5-4.5 meters for better air circulation
                • Orientation: East-West for uniform light distribution
                • Ventilation: 20-25% of floor area for proper air exchange
                • Covering Material: UV-stabilized polyethylene (200 micron) or polycarbonate
                
                **Crop Selection for Protected Cultivation:**
                
                High-Value Crops for Maximum Returns:
                • **Tomato**: Indeterminate varieties (Abhilash, Vaishali, US-618)
                • **Capsicum**: Colored varieties (Yellow, Red, Orange) for premium markets
                • **Cucumber**: Long English varieties, Lebanese cucumber for export
                • **Leafy Vegetables**: Lettuce, spinach, herbs for urban markets
                
                Yield Potential (per 1000 sqm polyhouse):
                • Tomato: 80-120 tons vs 25-35 tons in open field
                • Capsicum: 45-65 tons vs 15-20 tons in open field  
                • Cucumber: 70-90 tons vs 20-25 tons in open field
                • Leafy Vegetables: 15-20 crops per year vs 3-4 in open field
                
                **Advanced Growing Media and Nutrition:**
                
                Soilless Cultivation Systems:
                • **Coco Peat Medium**: 70% coco peat + 20% vermicompost + 10% perlite
                • **Hydroponic Systems**: NFT, DWC, Dutch bucket systems for precision nutrition
                • **Substrate Culture**: Rockwool, perlite, vermiculite for root zone management
                
                Precision Fertigation:
                • **EC Management**: 1.5-2.5 dS/m depending on crop and growth stage
                • **pH Control**: 5.5-6.5 for optimal nutrient uptake
                • **Nutritional Solutions**: Stage-specific NPK ratios (18:18:18 vegetative, 13:40:13 flowering)
                
                **Economic Analysis:**
                
                Investment Requirements (per 1000 sqm):
                • **NVPH Setup**: ₹8-12 lakhs including structure, irrigation, accessories
                • **Climate-Controlled**: ₹15-25 lakhs with automation and environmental control
                • **Annual Operating**: ₹2-4 lakhs including seeds, nutrition, labor, utilities
                
                Revenue Potential:
                • **Gross Returns**: ₹15-35 lakhs per year depending on crop and market
                • **Net Profit**: ₹8-20 lakhs per year after all expenses
                • **Payback Period**: 2-3 years for well-managed operations
                • **Premium Pricing**: 20-50% higher prices for protected cultivation produce
                """,
                "metadata": {
                    "title": "Advanced Vegetable Production Systems - Protected Cultivation",
                    "category": "vegetable_farming",
                    "region": "All India",
                    "crops": ["tomato", "capsicum", "cucumber", "leafy_vegetables"],
                    "source": "protected_cultivation_manual_2024",
                    "language": "en",
                    "expertise_level": "advanced",
                    "technology": ["polyhouse", "hydroponics", "precision_farming"],
                    "investment_level": "high",
                    "roi_timeline": "2-3 years"
                }
            }
        ]
        
        for doc in advanced_docs:
            await self.rag_pipeline.add_document(doc["content"], doc["metadata"])
        
        logger.info(f"Added {len(advanced_docs)} advanced crop knowledge documents")

async def main():
    """Initialize and build enhanced knowledge base"""
    try:
        # Initialize components
        embedding_service = EmbeddingService()
        response_generator = ResponseGenerator()
        index_store = IndexStore()
        
        # Create RAG pipeline
        rag_pipeline = RAGPipeline(
            embedding_service=embedding_service,
            response_generator=response_generator,
            index_store=index_store
        )
        
        # Initialize pipeline
        await rag_pipeline.initialize()
        
        # Build enhanced knowledge base
        knowledge_builder = EnhancedKnowledgeBuilder(rag_pipeline)
        await knowledge_builder.add_advanced_crop_knowledge()
        
        print("Enhanced agricultural knowledge base built successfully!")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(main())