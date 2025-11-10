"""
RAG Pipeline for FarmKart AI
Orchestrates the complete RAG workflow
"""

import asyncio
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime

from embeddings import EmbeddingService
from generator import ResponseGenerator
from index_store import IndexStore

logger = logging.getLogger(__name__)

class RAGPipeline:
    """Main RAG pipeline orchestrator"""
    
    def __init__(
        self,
        embedding_service: EmbeddingService,
        response_generator: ResponseGenerator,
        index_store: IndexStore,
        similarity_threshold: float = 0.3,
        max_context_chunks: int = 5
    ):
        """
        Initialize RAG pipeline
        
        Args:
            embedding_service: Embedding service instance
            response_generator: Response generator instance
            index_store: Index store instance
            similarity_threshold: Minimum similarity for retrieving chunks
            max_context_chunks: Maximum number of context chunks to use
        """
        self.embedding_service = embedding_service
        self.response_generator = response_generator
        self.index_store = index_store
        self.similarity_threshold = similarity_threshold
        self.max_context_chunks = max_context_chunks
        
        self.is_initialized = False
    
    async def initialize(self):
        """Initialize the pipeline"""
        try:
            logger.info("Initializing RAG pipeline...")
            
            # Check if model is available
            model_available = await self.response_generator.check_model_availability()
            if not model_available:
                logger.info("Model not found, attempting to pull...")
                success = await self.response_generator.pull_model()
                if not success:
                    logger.warning("Failed to pull model, will use fallback responses")
            
            # Load existing index or create sample knowledge base
            index_loaded = self.index_store.load_index()
            if not index_loaded:
                logger.info("No existing index found, creating sample knowledge base...")
                await self._create_sample_knowledge_base()
            
            self.is_initialized = True
            logger.info("RAG pipeline initialized successfully")
            
        except Exception as e:
            logger.error(f"Error initializing RAG pipeline: {e}")
            raise
    
    async def generate_response(
        self,
        question: str,
        context: Optional[str] = None,
        language: str = "en"
    ) -> Dict[str, Any]:
        """
        Generate response using RAG pipeline
        
        Args:
            question: User question
            context: Additional context
            language: Response language
            
        Returns:
            Response dictionary with answer, confidence, and sources
        """
        try:
            if not self.is_initialized:
                raise Exception("Pipeline not initialized")
            
            # Preprocess question
            processed_question = self.embedding_service.preprocess_text(question)
            
            # Add context to question if provided
            if context:
                processed_question = f"Context: {context}\n\nQuestion: {processed_question}"
            
            # Generate query embedding
            query_embedding = self.embedding_service.encode(processed_question)
            
            # Retrieve relevant chunks
            search_results = self.index_store.search(
                query_embedding,
                k=self.max_context_chunks,
                score_threshold=self.similarity_threshold
            )
            
            # Extract content chunks and sources
            context_chunks = []
            sources = []
            
            for result in search_results:
                context_chunks.append(result["content"])
                sources.append({
                    "content": result["content"][:200] + "..." if len(result["content"]) > 200 else result["content"],
                    "score": result["score"],
                    "metadata": result["metadata"]
                })
            
            # Generate response
            if context_chunks:
                logger.info(f"Found {len(context_chunks)} relevant chunks for query")
                response = await self.response_generator.generate_response(
                    question=question,
                    context_chunks=context_chunks,
                    language=language
                )
            else:
                logger.info("No relevant chunks found, using fallback response")
                response = {
                    "answer": self.response_generator.get_fallback_response(question),
                    "confidence": 0.2,
                    "model": "fallback",
                    "timestamp": datetime.utcnow().isoformat()
                }
            
            # Combine results
            final_response = {
                "answer": response["answer"],
                "confidence": response["confidence"],
                "sources": sources,
                "model": response.get("model", "unknown"),
                "retrieval_count": len(search_results),
                "processing_time": response.get("processing_time", 0)
            }
            
            return final_response
            
        except Exception as e:
            logger.error(f"Error in RAG pipeline: {e}")
            # Return fallback response
            return {
                "answer": "I apologize, but I'm experiencing technical difficulties. Please try again later or contact support.",
                "confidence": 0.0,
                "sources": [],
                "error": str(e)
            }
    
    async def add_document(
        self,
        content: str,
        metadata: Dict[str, Any],
        chunk_size: int = 500,
        chunk_overlap: int = 50
    ):
        """
        Add a new document to the knowledge base
        
        Args:
            content: Document content
            metadata: Document metadata
            chunk_size: Size of text chunks
            chunk_overlap: Overlap between chunks
        """
        try:
            # Chunk the document
            chunks = self._chunk_text(content, chunk_size, chunk_overlap)
            
            # Generate embeddings
            chunk_texts = [chunk["text"] for chunk in chunks]
            embeddings = self.embedding_service.encode(chunk_texts)
            
            # Prepare document metadata
            documents = []
            for i, chunk in enumerate(chunks):
                doc_metadata = metadata.copy()
                doc_metadata.update({
                    "content": chunk["text"],
                    "chunk_id": i,
                    "total_chunks": len(chunks),
                    "start_pos": chunk["start"],
                    "end_pos": chunk["end"],
                    "added_at": datetime.utcnow().isoformat()
                })
                documents.append(doc_metadata)
            
            # Add to index
            self.index_store.add_documents(embeddings, documents)
            self.index_store.save_index()
            
            logger.info(f"Added document with {len(chunks)} chunks to knowledge base")
            
        except Exception as e:
            logger.error(f"Error adding document: {e}")
            raise
    
    def _chunk_text(
        self,
        text: str,
        chunk_size: int = 500,
        chunk_overlap: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Chunk text into smaller pieces
        
        Args:
            text: Input text
            chunk_size: Size of each chunk
            chunk_overlap: Overlap between chunks
            
        Returns:
            List of chunks with metadata
        """
        chunks = []
        words = text.split()
        
        start = 0
        while start < len(words):
            # Calculate end position
            end = min(start + chunk_size, len(words))
            
            # Create chunk
            chunk_words = words[start:end]
            chunk_text = " ".join(chunk_words)
            
            chunks.append({
                "text": chunk_text,
                "start": start,
                "end": end,
                "word_count": len(chunk_words)
            })
            
            # Move start position (with overlap)
            start = end - chunk_overlap
            if start >= len(words):
                break
        
        return chunks
    
    async def update_knowledge_base(self):
        """Update the knowledge base with new content"""
        try:
            logger.info("Starting knowledge base update...")
            
            # This would typically scrape new content from sources
            # For now, we'll add some additional agricultural knowledge
            
            await self._add_additional_knowledge()
            
            logger.info("Knowledge base update completed")
            
        except Exception as e:
            logger.error(f"Error updating knowledge base: {e}")
            raise
    
    async def _create_sample_knowledge_base(self):
        """Create a comprehensive knowledge base with enhanced agricultural content"""
        try:
            logger.info("Creating comprehensive agricultural knowledge base...")
            
            # Enhanced agricultural knowledge with comprehensive coverage
            agricultural_docs = [
                {
                    "content": """
                    Complete Guide to Modern Rice (Paddy) Cultivation in India - Advanced Techniques
                    
                    Rice is the staple food crop of India, grown across 44 million hectares with diverse agro-climatic conditions.
                    
                    **Advanced Variety Selection for Different Regions:**
                    
                    For High Yielding Varieties (HYV):
                    • North India: Pusa Basmati 1121, Pusa Basmati 1509, HD-2967, PB-1 (Punjab)
                    • South India: ADT-43, CO-51, BPT-5204, MTU-1010 (Andhra Pradesh, Tamil Nadu)
                    • East India: IR-64, Lalat, Naveen, Varshadhan (West Bengal, Odisha)
                    • West India: Indrayani, Ambemohar, GR-101 (Maharashtra)
                    
                    Climate-Resilient Varieties:
                    • Drought Tolerant: Sahbhagi Dhan, DRR Dhan 42, Nagina 22
                    • Flood Tolerant: Swarna Sub1, IR64 Sub1, Samba Mahsuri Sub1
                    • Salt Tolerant: CSR-36, Luna Suvarna, CSR-43
                    • Short Duration (90-110 days): KDML-105, Vandana, Pratiksha
                    
                    **Precision Land Preparation & Water Management:**
                    
                    Modern Land Preparation:
                    • Laser land leveling: Reduces water requirement by 25-30%
                    • Summer deep plowing: Exposes pests, improves soil structure
                    • Green manuring: Dhaincha (60 kg/ha) 45 days before transplanting
                    • Puddling depth: 15-20 cm for proper root zone establishment
                    
                    Advanced Water Management (System of Rice Intensification - SRI):
                    • Alternate Wetting and Drying (AWD): Save 15-20% water
                    • Maintain 1-2 cm water during critical stages only
                    • Install piezometers for groundwater monitoring
                    • Use tensiometers for precise irrigation scheduling
                    
                    **Scientific Nutrient Management:**
                    
                    Balanced Fertilization (per hectare):
                    • Basal dose: 60 kg N + 30 kg P₂O₅ + 30 kg K₂O
                    • Top dressing: 60 kg N in 2-3 splits (tillering, panicle initiation)
                    • Micronutrients: Zinc sulfate 25 kg/ha, Iron sulfate if deficient
                    
                    Organic Integration:
                    • FYM/Compost: 5-7.5 tons/ha before final puddling
                    • Vermicompost: 2.5 tons/ha for organic matter enhancement
                    • Green leaf manure: 6-8 tons/ha for sustainable nutrition
                    • Biofertilizers: Azospirillum + PSB @ 2 kg/ha each
                    
                    **Integrated Pest and Disease Management:**
                    
                    Major Pest Management:
                    • Yellow Stem Borer: Pheromone traps (8-10/ha) + Trichogramma releases
                    • Brown Plant Hopper: Resistant varieties + neem oil spray
                    • Leaf Folder: Light traps + Bt spray during evening hours
                    • Gandhi Bug: Early detection through sweep net sampling
                    
                    Disease Control Strategies:
                    • Blast Disease: Seed treatment with Carbendazim + resistant varieties
                    • Bacterial Leaf Blight: Copper-based sprays + clean seed
                    • Sheath Blight: Proper plant spacing + Validamycin spray
                    • False Smut: Preventive sprays at boot leaf stage
                    
                    **Modern Transplanting & Direct Seeding:**
                    
                    Machine Transplanting:
                    • Rice transplanter use: 8-10 plants/hill, 20×20 cm spacing
                    • Mat nursery preparation: 25-28 day old seedlings
                    • Fuel cost: ₹1,500-2,000/ha vs ₹8,000-12,000/ha manual
                    
                    Direct Seeded Rice (DSR):
                    • Seed rate: 25-30 kg/ha for line sowing
                    • Pre-emergence herbicide: Pendimethalin 1.0 kg/ha
                    • Post-emergence: Bispyribac sodium at 20-25 DAS
                    • Water savings: 20-25% compared to transplanted rice
                    
                    **Harvest & Post-Harvest Technology:**
                    
                    Optimal Harvest Timing:
                    • Moisture content: 20-25% for long grain varieties
                    • Visual indicators: 80% grains turn golden yellow
                    • Use combine harvester: Reduces labor cost by 60-70%
                    
                    Post-Harvest Management:
                    • Immediate drying: Reduce moisture to 14% within 24 hours
                    • Scientific storage: Use hermetic bags or metal silos
                    • Quality premium: Proper drying increases market price by ₹200-500/quintal
                    
                    **Economic Analysis & Government Support:**
                    
                    Cost Economics (per hectare):
                    • Input cost: ₹35,000-45,000 (seeds, fertilizers, pesticides, labor)
                    • Yield potential: 50-70 quintals/ha (good management)
                    • Net profit: ₹25,000-40,000/ha (depending on variety & market)
                    
                    Government Schemes & Support:
                    • Pradhan Mantri Fasal Bima Yojana: Comprehensive crop insurance
                    • National Food Security Mission: Technical support & subsidies
                    • Sub-Mission on Agricultural Mechanization: Machinery subsidies
                    • Paramparagat Krishi Vikas Yojana: Organic farming promotion
                    
                    **Climate Change Adaptation:**
                    
                    Resilience Strategies:
                    • Early warning systems: Use weather forecasting apps
                    • Crop calendar adjustment: Shift sowing dates based on rainfall
                    • Water harvesting: Farm ponds for supplemental irrigation
                    • Carbon sequestration: Incorporate crop residues, avoid burning
                    
                    Technology Integration:
                    • Mobile apps: Crop Doctor, RiceAdvice, Weather forecasting
                    • Drone technology: Nutrient spray, pest monitoring
                    • Soil health cards: Regular testing and nutrient management
                    • Market intelligence: Real-time price information systems
                    """,
                    "metadata": {
                        "title": "Complete Guide to Modern Rice Cultivation in India - Advanced Techniques",
                        "category": "rice_cultivation",
                        "region": "All India",
                        "crops": ["rice", "paddy"],
                        "source": "advanced_rice_cultivation_guide_2024",
                        "language": "en",
                        "expertise_level": "comprehensive",
                        "government_schemes": ["PMFBY", "NFSM", "SMAM", "PKVY"],
                        "seasonal_relevance": ["kharif", "rabi", "summer"],
                        "technology": ["SRI", "DSR", "mechanization", "precision_farming"]
                    }
                },
                {
                    "content": """
                    Advanced Wheat Production Technology for Maximum Yield in Indian Conditions
                    
                    Wheat is the second most important cereal crop in India, covering 30 million hectares with huge potential for productivity enhancement.
                    
                    **High-Performance Variety Selection:**
                    
                    Mega Varieties for Different Zones:
                    • North Western Plain Zone: HD-2967, WH-147, PBW-343, HD-3086
                    • North Eastern Plain Zone: HD-2888, K-307, HD-2851, NW-2036  
                    • Central Zone: GW-366, HD-2967, MP-3288, JW-3211
                    • Peninsular Zone: UAS-304, NIAW-301, HD-2932, GW-273
                    • Hill Zone: VL-829, HPW-236, HS-365, VL-616
                    
                    Special Purpose Varieties:
                    • High Protein (>12%): Lok-1, K-68, HW-2045
                    • Disease Resistant: HD-2967 (rust resistant), WH-147 (multiple resistance)
                    • Heat Tolerant: HD-2888, DBW-14, WH-730
                    • Early Maturing: HD-2851, PBW-502, WH-542 (110-115 days)
                    
                    **Precision Sowing & Crop Establishment:**
                    
                    Scientific Seed Rate & Spacing:
                    • Irrigated conditions: 100 kg/ha for timely sown, 125 kg/ha for late sown
                    • Rain-fed conditions: 125-150 kg/ha depending on variety
                    • Row spacing: 18-23 cm for optimal plant population
                    • Sowing depth: 3-5 cm for proper germination
                    
                    Zero Tillage Technology:
                    • Direct sowing after rice harvest: Saves 15-20 days
                    • Fuel cost reduction: ₹2,000-3,000/ha compared to conventional tillage
                    • Moisture conservation: Better utilization of residual soil moisture
                    • Happy Seeder technology: Sow wheat through rice stubble
                    
                    **Advanced Irrigation Management:**
                    
                    Critical Irrigation Stages:
                    1. Crown Root Initiation (CRI): 20-25 DAS - Most critical
                    2. Late Tillering: 40-45 DAS - For tiller establishment
                    3. Late Jointing: 60-65 DAS - Spike development
                    4. Flowering: 85-90 DAS - Grain setting
                    5. Milk Stage: 105-110 DAS - Grain filling
                    6. Dough Stage: 115-120 DAS - Final grain development
                    
                    Water Use Efficiency:
                    • Drip irrigation in wheat: 30-40% water saving
                    • Sprinkler irrigation: 20-25% water saving
                    • Mulching: Wheat straw mulch saves 15-20% irrigation water
                    • Laser leveling: Uniform water distribution, 20-25% water saving
                    
                    **Integrated Nutrient Management:**
                    
                    Balanced Fertilization (120 kg N, 60 kg P₂O₅, 40 kg K₂O per hectare):
                    • Basal application: 1/3 N + full P + full K
                    • First top dressing: 1/3 N at CRI stage (20-25 DAS)
                    • Second top dressing: 1/3 N at late tillering (40-45 DAS)
                    
                    Micronutrient Management:
                    • Zinc: ZnSO₄ 25 kg/ha (soil application) or 0.5% foliar spray
                    • Iron: FeSO₄ 25 kg/ha in iron-deficient soils
                    • Sulfur: Through gypsum 200-300 kg/ha
                    • Boron: 1 kg/ha for grain quality improvement
                    
                    Organic Integration Strategy:
                    • FYM: 8-10 tons/ha before sowing
                    • Vermicompost: 2.5 tons/ha for soil health improvement
                    • Green manuring: Sesbania, dhaincha in summer fallow
                    • Biofertilizers: Azotobacter + PSB + KSB @ 25g/kg seed
                    
                    **Comprehensive Pest & Disease Management:**
                    
                    Major Disease Management:
                    • Rust Diseases (Yellow, Brown, Black):
                      - Use resistant varieties (Yr genes for yellow rust)
                      - Propiconazole 0.1% spray at boot leaf stage
                      - Avoid excessive nitrogen, ensure balanced nutrition
                      
                    • Powdery Mildew:
                      - Sulfur dusting @ 20-25 kg/ha
                      - Triadimefon 0.05% spray at early infection
                      - Maintain proper plant spacing for air circulation
                      
                    • Loose Smut & Karnal Bunt:
                      - Seed treatment with Vitavax or Raxil @ 2.5g/kg seed
                      - Use certified disease-free seeds
                      - Avoid irrigation during flowering
                    
                    Pest Control Strategies:
                    • Aphids: Economic threshold 5-10 aphids/tiller
                      - Lady bird beetles conservation
                      - Thiamethoxam 25 WG @ 100g/ha
                      
                    • Termites: Pre-sowing soil treatment
                      - Chlorpyrifos 20 EC @ 2.5 L/ha
                      - Use resistant varieties in endemic areas
                      
                    • Pink Stem Borer: Deep summer plowing
                      - Trichogramma releases @ 1 lakh/ha
                    
                    **Modern Harvest & Storage Technology:**
                    
                    Optimal Harvesting:
                    • Harvest at physiological maturity (35-40% moisture)
                    • Combine harvester efficiency: 8-10 ha/day
                    • Cost advantage: ₹3,000-4,000/ha vs manual harvesting
                    
                    Scientific Storage:
                    • Moisture content: Reduce to 12-14% before storage
                    • Storage structures: CAP storage, silos, hermetic bags
                    • Pest control: Aluminum phosphide fumigation
                    • Quality maintenance: Regular monitoring for temperature & moisture
                    
                    **Economic Analysis & Market Intelligence:**
                    
                    Production Economics (per hectare):
                    • Total cost: ₹40,000-50,000 (including land preparation to harvest)
                    • Expected yield: 45-55 quintals/ha (good management)
                    • Gross returns: ₹90,000-1,10,000/ha (MSP + bonus)
                    • Net profit: ₹40,000-60,000/ha
                    
                    Value Addition Opportunities:
                    • Wheat flour processing: 15-20% price premium
                    • Organic certification: 25-30% premium price
                    • Contract farming: Assured price + input supply
                    • Wheat straw management: Additional ₹5,000-8,000/ha income
                    
                    Government Support Systems:
                    • Minimum Support Price (MSP): ₹2,125/quintal (2024-25)
                    • Price Support Scheme: Procurement through FCI
                    • National Food Security Mission: Input subsidies
                    • PM-KISAN: Direct income support ₹6,000/year
                    
                    **Climate Resilience & Sustainability:**
                    
                    Heat Stress Management:
                    • Early sowing (October 25 - November 15)
                    • Heat tolerant varieties in terminal heat zones
                    • Foliar spray of potassium nitrate 1% at grain filling
                    • Mulching to reduce soil temperature
                    
                    Resource Conservation Technologies:
                    • Zero tillage: Fuel saving ₹2,500-3,500/ha
                    • Crop residue management: In-situ decomposition
                    • Precision nutrient management: Site-specific fertilizer use
                    • Water-efficient varieties: Reduced irrigation requirement
                    """,
                    "metadata": {
                        "title": "Advanced Wheat Production Technology for Maximum Yield in Indian Conditions",
                        "category": "wheat_cultivation", 
                        "region": "All India",
                        "crops": ["wheat"],
                        "source": "advanced_wheat_production_2024",
                        "language": "en", 
                        "expertise_level": "comprehensive",
                        "government_schemes": ["MSP", "NFSM", "PM-KISAN", "PSS"],
                        "seasonal_relevance": ["rabi"],
                        "technology": ["zero_tillage", "precision_farming", "mechanization"]
                    }
                },
                {
                    "content": """
                    Comprehensive Cotton Production & Integrated Crop Management System
                    
                    Cotton is India's most important cash crop, grown on 12.5 million hectares across diverse agro-climatic zones with significant export potential.
                    
                    **Advanced Hybrid & Bt Cotton Varieties:**
                    
                    Region-wise Superior Hybrids:
                    • North Zone (Punjab, Haryana, Rajasthan): 
                      - Bt Hybrids: RCH-317 Bt, MRC-7017 Bt, Ankur-651 Bt
                      - High Density Planting: Mallika, Suraj, CICR-1, CICR-2
                      
                    • Central Zone (Maharashtra, Gujarat, Madhya Pradesh):
                      - Bollgard II: RCH-650 BGII, MRC-7351 BG II, Ankur-3028 BG II  
                      - Desi varieties: G.Cot-23, CICR-1, AKH-081
                      
                    • South Zone (Andhra Pradesh, Telangana, Karnataka, Tamil Nadu):
                      - Bt Cotton: RCH-792 Bt, NCS-207 Bt, Mallika Bt
                      - Traditional: Surabhi, DCH-32, KBSH-44
                    
                    Specialty Cotton for Premium Markets:
                    • Extra Long Staple (ELS): Suvin, DCH-32 (35+ mm staple)
                    • Organic Cotton: HD-123, Mallika, CICR-1 (non-Bt varieties)
                    • Colored Cotton: Brown cotton varieties for niche markets
                    
                    **Scientific Sowing & Plant Population Management:**
                    
                    Optimal Planting Specifications:
                    • Bt Cotton: 90×60 cm spacing, 18,500 plants/ha
                    • High Density Planting System (HDPS): 67.5×10 cm, 1,48,000 plants/ha  
                    • Desi varieties: 90×30 cm spacing, 37,000 plants/ha
                    • Seed rate: 1.5-2.0 kg/ha for Bt hybrids, 4-5 kg/ha for desi varieties
                    
                    Precision Sowing Technology:
                    • Ridge planting: Better drainage and root aeration
                    • GPS-guided planters: Uniform plant population
                    • Seed treatment: Imidacloprid 70WS @ 7g/kg + fungicide
                    • Inter-cropping: Cotton + green gram/black gram (1:1 or 2:1 ratio)
                    
                    **Advanced Water & Nutrient Management:**
                    
                    Drip Irrigation System Design:
                    • Water requirement: 700-1200 mm depending on region
                    • Critical stages: Square formation, flowering, boll development
                    • Drip system: 16 mm lateral pipes, 4 L/hr drippers, 60 cm spacing
                    • Fertigation: Apply 70% nutrients through drip system
                    
                    Precision Nutrient Management:
                    • Soil testing based fertilization: NPK according to soil analysis
                    • Balanced nutrition: 150:75:75 kg NPK/ha for irrigated cotton
                    • Split application: 25% basal, 50% at square formation, 25% at flowering
                    • Micronutrients: Zn, B, Fe foliar sprays at critical stages
                    
                    Organic Integration Model:
                    • FYM/Compost: 7.5-10 tons/ha before sowing
                    • Vermicompost: 2.5 tons/ha for soil biology enhancement  
                    • Green manuring: Dhaincha, sunhemp in summer fallow
                    • Biofertilizers: Azotobacter + PSB + Trichoderma seed treatment
                    
                    **Integrated Pest Management (IPM) for Cotton:**
                    
                    Early Season Pest Management:
                    • Thrips: Blue sticky traps @ 10-12/acre + imidacloprid seed treatment
                    • Jassids: Economic threshold 1 nymph/3 leaves (ETL)
                    • Aphids: Conserve natural enemies, avoid broad spectrum insecticides
                    
                    Bollworm Complex Management:
                    • American Bollworm (Helicoverpa): 
                      - Pheromone traps @ 4-5/acre for monitoring
                      - Nuclear Polyhedrosis Virus (NPV) @ 250 LE/ha
                      - Bt expression monitoring in Bt cotton
                      
                    • Pink Bollworm: 
                      - Bt cotton varieties with Cry1Ac + Cry2Ab genes
                      - Pheromone traps for adult monitoring
                      - Crop sanitation: Deep plowing after harvest
                      
                    • Spotted Bollworm:
                      - Early variety selection to avoid peak infestation
                      - Trichogramma releases @ 1 lakh/ha/week
                    
                    Sucking Pest Complex:
                    • Whitefly Management:
                      - Yellow sticky traps @ 8-10/acre
                      - Spiromesifen 240 SC @ 600 ml/ha (rotation)
                      - Reflective mulches to repel whiteflies
                      
                    • Mealybug Control:
                      - Ant management using borax baits
                      - Parasitoid releases: Aenasius bambawalei
                      - Soil application of imidacloprid in endemic areas
                    
                    **Advanced Disease Management:**
                    
                    Wilt Disease Complex:
                    • Fusarium & Verticillium Wilt:
                      - Resistant varieties: G.Cot-23, CICR-1, CICR-2
                      - Soil solarization during summer months
                      - Trichoderma harzianum soil treatment @ 2.5 kg/ha
                      - Avoid excessive nitrogen, maintain soil pH 6.5-7.5
                    
                    Bacterial Blight:
                    • Seed treatment with streptocycline @ 200 ppm
                    • Copper-based fungicides: Copper oxychloride 0.25%
                    • Field sanitation: Removal of infected plant debris
                    • Avoid overhead irrigation during humid conditions
                    
                    **Modern Harvest & Fiber Quality Management:**
                    
                    Scientific Picking Protocol:
                    • First picking: 80-90% bolls open (90-95 DAS)
                    • Subsequent pickings: 15-20 day intervals
                    • Morning harvest: Better fiber quality, reduced contamination
                    • Hand picking vs machine: Quality considerations
                    
                    Fiber Quality Enhancement:
                    • Ginning: Modern roller gins for better staple length
                    • Storage: Moisture content <8%, avoid contamination
                    • Grading: HVI (High Volume Instrument) testing
                    • Premium quality parameters: 28+ mm staple, 25+ strength
                    
                    **Economic Analysis & Market Dynamics:**
                    
                    Production Economics (per hectare):
                    • Input costs: ₹55,000-75,000 (seeds to harvest)
                    • Expected yield: 20-25 quintals/ha (good management)  
                    • Gross returns: ₹1,25,000-1,75,000/ha (MSP + premium)
                    • Net profit: ₹50,000-1,00,000/ha depending on yield & price
                    
                    Value Chain Opportunities:
                    • Contract farming: Assured procurement + input supply
                    • Organic certification: 15-20% price premium
                    • FPO marketing: Direct mill sales, better prices
                    • Ginning & pressing: Value addition at farm level
                    
                    Export Market Dynamics:
                    • India's position: 2nd largest cotton producer globally
                    • Quality requirements: ELS cotton for premium exports
                    • Traceability systems: Blockchain for organic cotton
                    • Sustainability certifications: Better Cotton Initiative (BCI)
                    
                    **Technology Integration & Precision Agriculture:**
                    
                    Digital Cotton Farming:
                    • Mobile apps: Cotton Doctor, CottonAce for pest identification
                    • Weather-based advisories: Sowing, irrigation, pest management
                    • Soil health monitoring: Real-time nutrient status
                    • Market intelligence: Price forecasting, demand trends
                    
                    Mechanization Options:
                    • Cotton picker machines: 8-10 times faster than hand picking
                    • Precision planters: Uniform seed placement and spacing
                    • Fertigation systems: Automated nutrient delivery
                    • Drone technology: Pest monitoring, precise chemical application
                    
                    Government Support & Schemes:
                    • Technology Mission on Cotton: Research & development support
                    • MSP for Cotton: ₹6,620/quintal (2024-25 season)
                    • Mini Mission II: Integrated approach to cotton development
                    • Cotton Corporation of India: Price support operations
                    • National Mission on Oilseeds & Oil Palm: Related crop support
                    """,
                    "metadata": {
                        "title": "Comprehensive Cotton Production & Integrated Crop Management System",
                        "category": "cotton_farming",
                        "region": "All India", 
                        "crops": ["cotton", "bt_cotton"],
                        "source": "advanced_cotton_production_2024",
                        "language": "en",
                        "expertise_level": "comprehensive", 
                        "government_schemes": ["TMC", "MSP", "Mini_Mission_II", "CCI"],
                        "seasonal_relevance": ["kharif"],
                        "technology": ["bt_technology", "precision_farming", "mechanization", "drip_irrigation"]
                    }
                }
            ]
            
            # Add documents to knowledge base
            for doc in agricultural_docs:
                await self.add_document(doc["content"], doc["metadata"])
            
            logger.info(f"Added {len(agricultural_docs)} comprehensive documents to knowledge base")
            
        except Exception as e:
            logger.error(f"Error creating comprehensive knowledge base: {e}")
            raise
    
    async def _add_additional_knowledge(self):
        """Add additional agricultural knowledge"""
        try:
            additional_docs = [
                {
                    "content": """
                    Comprehensive Organic Fertilizers and Sustainable Nutrient Management
                    
                    Organic fertilizers provide slow-release nutrients while improving soil health, water retention, and beneficial microbial activity.
                    
                    Major types of organic fertilizers for Indian agriculture:
                    
                    1. Farmyard Manure (FYM):
                    - Composition: 0.5% N, 0.2% P₂O₅, 0.5% K₂O
                    - Application rate: 10-15 tonnes per hectare
                    - Best time: Apply 2-3 weeks before sowing
                    - Preparation: Well-decomposed cattle dung mixed with crop residues
                    - Regional names: Gobar khad (Hindi), Eerugula yenugu (Telugu)
                    
                    2. Vermicompost (Earthworm Castings):
                    - Composition: 1.0-1.5% N, 0.8-1.2% P₂O₅, 0.8-1.0% K₂O
                    - Application rate: 2-3 tonnes per hectare
                    - Advantages: Rich in growth hormones, improves soil structure
                    - Production: Use Eisenia fetida worms with organic waste
                    - Cost-effective: Can be produced on-farm using kitchen waste
                    
                    3. Compost (Aerobic Decomposition):
                    - Composition: 0.8-1.2% N, 0.4-0.8% P₂O₅, 0.8-1.2% K₂O
                    - Application rate: 5-8 tonnes per hectare
                    - NADEP method: Popular composting technique in India
                    - Ingredients: Crop residues, animal waste, kitchen scraps, green leaves
                    - Maturation time: 3-4 months for complete decomposition
                    
                    4. Green Manure Crops:
                    Summer green manure:
                    - Dhaincha (Sesbania aculeata): 150-200 kg N per hectare
                    - Sunhemp (Crotalaria juncea): 120-150 kg N per hectare
                    - Cowpea (Vigna unguiculata): 80-120 kg N per hectare
                    
                    Winter green manure:
                    - Berseem (Trifolium alexandrinum): 100-150 kg N per hectare
                    - Lentil (Lens culinaris): 60-80 kg N per hectare
                    - Mustard (Brassica campestris): Improves phosphorus availability
                    
                    5. Liquid Organic Fertilizers:
                    
                    Panchagavya preparation:
                    - Ingredients: Cow dung (5 kg), cow urine (3 L), milk (2 L), curd (2 L), ghee (1 kg), banana (12 pieces), tender coconut water (3 L), jaggery (3 kg)
                    - Fermentation: 15-20 days with daily stirring
                    - Application: 30-50 ml per liter water for foliar spray
                    - Benefits: Growth promoter, pest deterrent, stress tolerance
                    
                    Jeevamrutha preparation:
                    - Ingredients: Cow dung (10 kg), cow urine (10 L), jaggery (2 kg), pulse flour (2 kg), live soil (1 handful)
                    - Preparation time: 48 hours fermentation
                    - Application: 200 L per acre as soil drench
                    - Frequency: Every 15 days during crop growth
                    
                    6. Biofertilizers for Nitrogen Fixation:
                    
                    Rhizobium inoculation:
                    - Target crops: All legumes (pulses, soybean, groundnut)
                    - Application: 5-10 g per kg seed before sowing
                    - Benefits: 20-30 kg N per hectare from biological fixation
                    - Storage: Keep in cool, dry place away from chemicals
                    
                    Azotobacter inoculation:
                    - Target crops: All non-leguminous crops
                    - Application: 5-10 g per kg seed
                    - Benefits: 15-25 kg N per hectare through atmospheric fixation
                    - Additional benefits: Growth hormones production, phosphorus solubilization
                    
                    PSB (Phosphorus Solubilizing Bacteria):
                    - Target crops: All crops, especially in P-deficient soils
                    - Application: 5-10 g per kg seed or 2 kg per hectare soil application
                    - Benefits: Makes unavailable phosphorus available to plants
                    - Cost saving: Reduces chemical phosphorus fertilizer requirement by 25-30%
                    
                    Integrated nutrient management for major Indian crops:
                    
                    Rice-Wheat System:
                    - FYM: 5-7.5 tonnes per hectare once a year
                    - Chemical fertilizers: Reduce NPK by 25% when using organics
                    - Green manure: Dhaincha in summer fallow
                    - Biofertilizers: Azotobacter + PSB for both crops
                    
                    Cotton:
                    - Vermicompost: 2.5 tonnes per hectare
                    - Neem cake: 250 kg per hectare (pest deterrent + nutrient)
                    - Foliar spray: Panchagavya at square formation and flowering
                    - Chemical fertilizer reduction: 30-40% with organic inputs
                    
                    Vegetables (Tomato, Brinjal, Chili):
                    - Well-decomposed FYM: 20-25 tonnes per hectare
                    - Vermicompost: 2-3 tonnes per hectare
                    - Jeevamrutha: Every 15 days through drip irrigation
                    - Biofertilizers: Azotobacter + PSB + Trichoderma (disease control)
                    
                    Economic and environmental benefits:
                    - Soil organic carbon increase: 0.1-0.3% annually with organic inputs
                    - Water holding capacity improvement: 15-25%
                    - Fertilizer cost reduction: 25-40%
                    - Yield stability: Better performance during stress conditions
                    - Soil biology enhancement: Increased microbial diversity
                    - Carbon sequestration: 0.5-1.0 tonnes CO₂ per hectare per year
                    - Premium market price: 10-20% higher for organic produce
                    
                    Government support schemes:
                    - Paramparagat Krishi Vikas Yojana (PKVY): Financial support for organic farming
                    - National Mission for Sustainable Agriculture (NMSA): Promotes organic inputs
                    - Rashtriya Krishi Vikas Yojana (RKVY): State-level organic farming promotion
                    - Organic certification support: NPOP (National Programme for Organic Production)
                    """,
                    "metadata": {
                        "title": "Comprehensive Organic Fertilizers and Sustainable Nutrient Management",
                        "category": "fertilizers",
                        "region": "India",
                        "crops": ["rice", "wheat", "cotton", "vegetables", "pulses"],
                        "source": "organic_farming_guide_india",
                        "language": "en",
                        "expertise_level": "comprehensive",
                        "government_schemes": ["PKVY", "NMSA", "RKVY", "NPOP"]
                    }
                },
                {
                    "content": """
                    Climate-Smart Agriculture and Weather-Based Farming for Indian Conditions
                    
                    Climate-smart agriculture integrates weather information, climate resilience, and sustainable practices to optimize farm productivity while adapting to climate change.
                    
                    Understanding Indian weather patterns for farming decisions:
                    
                    1. Monsoon and Cropping Seasons:
                    
                    Southwest Monsoon (June-September):
                    - Kharif season: Rice, cotton, sugarcane, millets, pulses
                    - Onset dates: Kerala (June 1), Delhi (June 29), Rajasthan (July 15)
                    - Rainfall contribution: 70-80% of annual precipitation
                    - Critical for rain-fed agriculture in most of India
                    
                    Northeast Monsoon (October-December):
                    - Rabi season preparation in South India
                    - Important for Tamil Nadu, Andhra Pradesh, Karnataka
                    - Winter rice cultivation in coastal areas
                    - Cyclone season in Bay of Bengal
                    
                    Winter Season (October-March):
                    - Rabi crops: Wheat, barley, mustard, gram, pea
                    - Requires irrigation in most areas
                    - Favorable temperature and humidity conditions
                    - Harvest period for Kharif crops
                    
                    Summer Season (April-May):
                    - Summer crops: Fodder maize, sunflower, watermelon
                    - Land preparation for Kharif season
                    - Water scarcity period in many regions
                    - High temperature stress on crops
                    
                    2. Weather-Based Crop Management:
                    
                    Temperature Management:
                    
                    Heat stress mitigation:
                    - Mulching: Reduces soil temperature by 3-5°C
                    - Shade nets: 25-50% shade for vegetable nurseries
                    - Irrigation timing: Early morning (4-7 AM) or evening (6-8 PM)
                    - Foliar spray: Kaolin clay (3%) reduces leaf temperature
                    - Variety selection: Heat-tolerant cultivars for summer cultivation
                    
                    Cold protection measures:
                    - Wind breaks: Tall crops or trees on northern side
                    - Smoking: Traditional method for frost protection
                    - Sprinkler irrigation: Continuous sprinkling during frost nights
                    - Row covers: Polythene tunnels for vegetable crops
                    - Delayed planting: Avoid extremely cold periods for sensitive crops
                    
                    Rainfall and Water Management:
                    
                    Excess rainfall management:
                    - Drainage systems: Open drains every 20-30 meters in heavy rainfall areas
                    - Raised bed cultivation: Prevents waterlogging in vegetables
                    - Resistant varieties: Flood-tolerant rice varieties (Swarna Sub1, IR64 Sub1)
                    - Disease management: Increased fungicide application during wet periods
                    - Harvest timing: Early harvest before heavy rainfall periods
                    
                    Drought management strategies:
                    - Deficit irrigation: Apply water at critical crop growth stages only
                    - Drought-tolerant crops: Millets, sorghum, castor, safflower
                    - Mulching: Conserves 40-60% soil moisture
                    - Anti-transpirants: Kaolin, glycerol reduce water loss
                    - Early sowing: Escape terminal drought stress
                    
                    3. Agro-Meteorological Advisory Services:
                    
                    IMD Weather Forecasting:
                    - District-level weather forecast: 5-day prediction accuracy 85-90%
                    - Seasonal forecast: Monsoon onset and withdrawal dates
                    - Extreme weather alerts: Cyclone, hailstorm, heat wave warnings
                    - Crop-specific advisories: Sowing, irrigation, pest management timing
                    
                    Automatic Weather Stations (AWS):
                    - Parameters: Temperature, humidity, rainfall, wind speed, solar radiation
                    - Location: One AWS per 25-30 km² area
                    - Data frequency: Hourly observations
                    - Farmer access: Through mobile apps and SMS services
                    
                    Agromet Advisory Bulletins:
                    - Weekly advisories for each agro-climatic zone
                    - Crop-specific recommendations based on weather forecast
                    - Pest and disease outbreak predictions
                    - Market intelligence linked with weather patterns
                    
                    4. Climate Change Adaptation Strategies:
                    
                    Crop Diversification:
                    - Shift to climate-resilient crops: Millets instead of water-intensive crops
                    - Multiple cropping systems: Intercropping, relay cropping
                    - Agroforestry: Trees provide microclimate modification
                    - Livestock integration: Mixed farming systems for risk distribution
                    
                    Water Resource Management:
                    - Rainwater harvesting: Farm ponds, check dams, percolation tanks
                    - Groundwater recharge: Recharge wells, bunding
                    - Efficient irrigation: Drip and sprinkler systems
                    - Crop calendar adjustment: Based on changing rainfall patterns
                    
                    Soil Health Management:
                    - Organic matter enhancement: Improves water and heat stress tolerance
                    - Cover cropping: Protects soil from extreme weather
                    - Conservation agriculture: Reduces soil erosion and moisture loss
                    - Biochar application: Improves soil water retention and carbon storage
                    
                    5. Technology Tools for Weather-Smart Farming:
                    
                    Mobile Applications:
                    - Meghdoot: IMD weather forecast app
                    - Kisan Suvidha: Integrated weather and farming advice
                    - Crop Insurance App: Weather-based insurance information
                    - Damini: Lightning and thunderstorm alerts
                    
                    Satellite-based Services:
                    - ISRO's KISAN portal: Crop area, yield estimation
                    - Drought monitoring: Using NDVI and rainfall data
                    - Flood mapping: Real-time flood extent mapping
                    - Crop insurance: Satellite-based crop loss assessment
                    
                    Economic Benefits of Weather-Smart Farming:
                    - Crop loss reduction: 15-25% through timely interventions
                    - Input cost optimization: 10-20% savings on irrigation and chemicals
                    - Quality improvement: Better produce quality with weather-based management
                    - Insurance premiums: Lower premiums for adopting climate-smart practices
                    - Market timing: Better prices through weather-informed harvest timing
                    
                    Government Initiatives:
                    - National Mission on Climate Change: Promotes climate-smart agriculture
                    - Pradhan Mantri Fasal Bima Yojana: Weather-based crop insurance
                    - Climate-Resilient Agriculture Programme: Technology demonstration
                    - Gramin Krishi Mausam Seva: Village-level weather advisory services
                    """,
                    "metadata": {
                        "title": "Climate-Smart Agriculture and Weather-Based Farming for Indian Conditions",
                        "category": "weather",
                        "region": "India",
                        "crops": ["rice", "wheat", "cotton", "millets", "vegetables"],
                        "source": "climate_smart_agriculture_india",
                        "language": "en",
                        "expertise_level": "comprehensive",
                        "government_schemes": ["PMFBY", "NMCC", "CRAP", "GKMS"],
                        "technology": ["AWS", "satellite", "mobile_apps"]
                    }
                }
            ]
            
            for doc in additional_docs:
                await self.add_document(doc["content"], doc["metadata"])
            
            logger.info("Added additional agricultural knowledge")
            
        except Exception as e:
            logger.error(f"Error adding additional knowledge: {e}")
            raise
    
    def get_pipeline_stats(self) -> Dict[str, Any]:
        """Get pipeline statistics"""
        return {
            "is_initialized": self.is_initialized,
            "similarity_threshold": self.similarity_threshold,
            "max_context_chunks": self.max_context_chunks,
            "embedding_dimension": self.embedding_service.get_embedding_dimension(),
            "index_stats": asyncio.run(self.index_store.get_statistics()) if self.index_store else {}
        }