# 📊 DocLinker RAG Architecture Flowcharts

## 🏗️ **Overall System Architecture**

```
User Input → Processing Mode
              ↓         ↓
         LLM Path   Vector Path
              ↓         ↓
         Groq API   HuggingFace
              ↓         ↓
        Specialty   Embedding
         Match       Match
              ↓         ↓
              Firestore DB
                   ↓
              Ranked Results
                   ↓
              User Interface
```

## 🤖 **Enhanced Medical Assistant Flow**

```
User: "I have chest pain"
       ↓
UI: Switch to Find Doctor Mode
       ↓
LLM: Analyze symptoms → JSON
       ↓
UI: Parse {explanation, specialties}
       ↓
UI: Show loading animation
       ↓
DB: Query by specialties
       ↓
DB: Filter & rank doctors
       ↓
UI: Display results
```

## 🔍 **RAG Vector Matching Flow**

```
Symptom Input → HuggingFace → 384-dim Vector
                                   ↓
Doctor Profiles → Text Creation → Embeddings → Firestore
                                              ↓
                              Cosine Similarity
                                   ↓
                              Threshold Filter (≥0.1)
                                   ↓
                              Sort & Rank Results
```

## ⚙️ **Embedding Generation Pipeline**

```
New Doctor → Has Embedding? 
                ↓        ↓
              Skip     Create Profile Text
                       (Specializations + Degree + Keywords)
                               ↓
                       HuggingFace API Available?
                           ↓        ↓
                       API Call   Fallback
                           ↓        ↓
                         384-dim Vector
                               ↓
                         Store in Firestore
```

## 🎯 **Specialty Matching Algorithm**

```
Target Specialty → Doctor Specialty
                        ↓
                 Exact Match? → Score: 1.0
                        ↓
                 Partial Match? → Score: 0.7
                        ↓
                 Related Match? → Score: 0.6-0.9
                        ↓
                 No Match → Score: 0.0
                        ↓
                 Sort by Score → Top Results
```

## 🔄 **Dual-Path Processing Decision**

```
User Query → Chat Mode?
               ↓        ↓
         Simple Chat  Find Doctor
               ↓        ↓
         LLM Response  Medical Assistant
               ↓        ↓
         Chat UI      LLM Analysis + RAG
                           ↓
                    Doctor Recommendations
```

## 🛡️ **Error Handling & Fallback Flow**

```
API Request → Available?
                ↓      ↓
            Success  Failed
                ↓      ↓
         Real Embedding → Fallback
                ↓         ↓
           Validate → Deterministic
                ↓         ↓
            Store in Database
                ↓
         Continue Processing
```

## 📊 **Performance Optimization Flow**

```
User Query → Cache Hit?
               ↓      ↓
          Cached    Process
          Results      ↓
               ↓   Firestore Query
               ↓       ↓
               ↓   Pre-computed 
               ↓   Embeddings
               ↓       ↓
               ↓   Rank Results
               ↓       ↓
             Client Response
```

## 🔗 **Data Flow Architecture**

```
Input (100%) → LLM (60%) + Vector (40%)
                 ↓            ↓
              Groq API    HuggingFace
                 ↓            ↓
              Specialty   Embedding
                 ↓            ↓
                Doctor Search (100%)
                       ↓
                 User Interface
```

## 🎯 **End-to-End User Journey**

```
1. User: Open App → Find Doctor Mode
2. User: Describe Symptoms
3. System: AI Analysis (LLM + Embeddings)
4. System: Search & Rank Doctors
5. User: View Results → Book Appointment
```