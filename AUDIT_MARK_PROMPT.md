# Prompt: Implement Audit Mark System

Copy this entire prompt to AI (Claude/ChatGPT) to implement audit mark functionality in your Django project.

---

## WHAT TO BUILD

A system that automatically adds **audit mark symbols** to document footers when users download Word/Excel files.

**Business Purpose:**
Auditors mark documents with symbols (✓, ◊, ★) to indicate which audit procedures were performed. When downloading a document, the system matches relevant marks to that document and adds them to the footer automatically.

**Example:**
- User downloads "A1 Balance Sheet.docx"
- System finds marks with work_paper="A-1"
- Document footer shows:
  ```
  MARCAS DE AUDITORÍA UTILIZADAS:
  ✓ Verified with bank statement
  ◊ Reviewed and confirmed
  ```

---

## CORE REQUIREMENTS

### 1. Database Model

Create a model to store audit marks with these fields:
- Link to audit (ForeignKey)
- Mark description (text, e.g., "Verified with bank statement")
- Symbol (text, e.g., "✓", "◊", "★")
- Work paper number (text, e.g., "A-1", "WP-02") - used for matching
- Category (optional text, e.g., "Cash", "Inventory")
- Active flag (boolean, default true)
- Timestamps

**Business Logic:**
- Each audit can have multiple marks
- Marks with "Ejemplo:" in description are test data - exclude them
- Use Django admin for manual mark entry

---

### 2. Document Matching Algorithm

**Goal:** Determine which marks apply to each document

**Matching Rule:**
Compare document filename (without extension) with mark's work_paper_number:
- Normalize both: uppercase, remove spaces/hyphens/dots
- Check if work_paper is substring of filename (or vice versa)
- If match → include mark in footer

**Examples:**
```
✓ Match: filename="A 1 Balance.docx", work_paper="A-1"
   → "A1BALANCE" contains "A1"

✓ Match: filename="WP02 Cash.xlsx", work_paper="WP-02"
   → "WP02CASH" contains "WP02"

✗ No match: filename="B2 Inventory.docx", work_paper="A-1"
   → "B2INVENTORY" doesn't contain "A1"
```

**Critical:** Only show marks that ACTUALLY match - never show all marks.

---

### 3. Document Processing Service

Create a service class that:

**Input:**
- Document file path
- Original filename
- Audit ID

**Process:**
1. Load active marks for this audit (exclude "Ejemplo:" marks)
2. Match marks to document using algorithm above
3. If matches found:
   - For Word (.docx): Add marks to footer section
   - For Excel (.xlsx): Add marks section at bottom of sheet
4. Return processed document

**Output:** Modified document with marks in footer/bottom

---

### 4. Footer Injection (Word Documents)

**Requirements:**
- Add section titled "MARCAS DE AUDITORÍA UTILIZADAS:"
- List each mark as: `{symbol}  {description}`
- Style: Bold, 11pt, Professional Blue (#0070C0), Left-aligned
- Apply to ALL document sections
- Use document's existing font family

**Important:** ONLY modify footer - never touch document body, tables, or content.

---

### 5. Marks Section (Excel Documents)

**Requirements:**
- Find last row with data
- Add 3 blank rows
- Add header: "MARCAS DE AUDITORÍA UTILIZADAS:" (merged cells, bold, blue)
- Add each mark: `{symbol}  {description}` (bold, blue, gray background)
- Start at column B

**Important:** ONLY add new rows at bottom - never modify existing data cells.

---

### 6. Download Integration

Modify document download view to:
1. Copy template to temporary file
2. Apply existing replacements (audit info, dates, etc.)
3. **Call document processing service** to inject marks
4. Return processed file to user

**Flow:**
```
User clicks download
  ↓
Copy template
  ↓
Apply replacements (existing logic)
  ↓
Inject audit marks (NEW)
  ↓
Return to user
```

---

## CRITICAL SAFETY RULES

### ⚠️ NEVER Modify These:
1. ❌ Document body content
2. ❌ Table data (especially financial numbers)
3. ❌ Headers
4. ❌ Existing formatting
5. ❌ Images or charts

### ✅ ONLY Allowed:
1. ✅ Read filename for matching
2. ✅ Read document title for matching
3. ✅ Add/modify footer content (Word)
4. ✅ Add new rows at bottom (Excel)

**Why Critical:**
Previous bugs caused financial data loss when code accidentally modified table cells. The processing service must be 100% read-only except for footers.

---

## SPECIAL CASES

### Case 1: PROGRAMA Files
**Rule:** Skip mark processing entirely for files with "PROGRAMA" in filename
**Reason:** These files contain hyperlinks that break during processing
**Implementation:** Check filename, if contains "PROGRAMA" → return unchanged

### Case 2: No Matches Found
**Rule:** If no marks match document → don't add footer at all
**Reason:** Empty footers look unprofessional
**Implementation:** If matched_marks empty → return unchanged

### Case 3: Example/Test Marks
**Rule:** Exclude marks with "Ejemplo:" in description
**Reason:** These are test data added during development
**Implementation:** Filter out in database query

---

## TECHNICAL DETAILS

**Django Version:** 5.0.6+

**Required Libraries:**
- `python-docx` for Word processing
- `openpyxl` for Excel processing

**File Locations (Suggested):**
- Model: `{app}/models.py`
- Service: `{app}/services/document_processor.py`
- View: `{app}/views/download_views.py`
- Admin: `{app}/admin.py`

**Performance:**
- Only process .docx and .xlsx files
- Check if audit has marks before processing (optimization)
- Use temp files - never modify templates directly

---

## BUSINESS WORKFLOW

**Setup (Admin):**
1. Admin creates audit marks via Django admin
2. Each mark has: description, symbol, work_paper_number

**Usage (Auditor):**
1. Auditor browses audit folder structure
2. Clicks to download document
3. System automatically adds relevant marks to footer
4. Auditor receives document with marks

**No Manual Steps:** Marks appear automatically based on matching logic.

---

## VALIDATION & TESTING

**Test Case 1: Basic Matching**
- Create mark: work_paper="A-1"
- Download file: "A 1 Balance.docx"
- Expected: Footer contains this mark

**Test Case 2: No Match**
- Create mark: work_paper="A-1"
- Download file: "B 2 Inventory.docx"
- Expected: No footer added

**Test Case 3: Multiple Matches**
- Create 2 marks: work_paper="A-1", work_paper="A1"
- Download file: "A1 Cash.docx"
- Expected: Footer contains both marks

**Test Case 4: PROGRAMA Exception**
- Download file: "PROGRAMA Audit.docx"
- Expected: No processing, file unchanged

**Test Case 5: Data Preservation**
- Download Excel with financial table
- Expected: All numbers identical before/after processing

---

## SUCCESS CRITERIA

✅ Marks appear in document footers
✅ Only matched marks shown (not all marks)
✅ Document content unchanged
✅ Financial data intact
✅ PROGRAMA files skip processing
✅ No "Ejemplo:" marks shown
✅ Works for both Word and Excel
✅ Styled professionally (blue, bold, clear)

---

## CAUTIONARY NOTES

### 🔴 HIGH RISK AREAS

**1. Table Modification Risk**
- **Danger:** Accidentally clearing table cells when processing
- **Impact:** Financial data loss - CRITICAL
- **Prevention:** Service must be READ-ONLY for document body
- **Check:** Verify all table data matches original after processing

**2. Matching Too Broad**
- **Danger:** Showing all marks in every document
- **Impact:** Incorrect audit documentation
- **Prevention:** Only add footer if matches found
- **Check:** Test with documents that shouldn't match

**3. Encoding Issues**
- **Danger:** Special symbols (✓, ◊, ★) display as question marks
- **Impact:** Unprofessional output
- **Prevention:** Ensure UTF-8 encoding throughout
- **Check:** Verify symbols appear correctly in downloaded files

**4. PROGRAMA File Corruption**
- **Danger:** Breaking hyperlinks in program documents
- **Impact:** Audit workflow disruption
- **Prevention:** Skip processing entirely if "PROGRAMA" in name
- **Check:** PROGRAMA file hyperlinks work after download

**5. Performance Degradation**
- **Danger:** Slow downloads for large documents
- **Impact:** Poor user experience
- **Prevention:** Check if marks exist before processing, use temp files
- **Check:** Download time should be <3 seconds for typical documents

### 🟡 MEDIUM RISK AREAS

**6. Memory Leaks**
- **Issue:** Not closing document/workbook objects
- **Prevention:** Use try/finally or context managers
- **Check:** Monitor memory usage during bulk downloads

**7. File Path Issues**
- **Issue:** Path separators differ on Windows/Linux
- **Prevention:** Use `os.path.join()` or pathlib
- **Check:** Test on both operating systems

**8. Race Conditions**
- **Issue:** Multiple users downloading same document simultaneously
- **Prevention:** Use unique temp file names (e.g., with timestamp/UUID)
- **Check:** Simulate concurrent downloads

### 🟢 LOW RISK (But Test)

**9. Empty Mark Fields**
- **Issue:** Mark with null work_paper_number
- **Prevention:** Handle null/empty gracefully in matching
- **Check:** Create mark without work_paper, ensure no crashes

**10. Very Long Descriptions**
- **Issue:** Mark description 500+ characters
- **Prevention:** Truncate or word-wrap in footer
- **Check:** Test with long descriptions

---

## IMPLEMENTATION NOTES FOR AI

**You should:**
1. ✅ Create clean, well-documented code
2. ✅ Follow Django best practices
3. ✅ Use type hints where appropriate
4. ✅ Add docstrings explaining business logic
5. ✅ Include error handling
6. ✅ Use logging for debugging
7. ✅ Make code testable
8. ✅ Consider edge cases

**You should NOT:**
1. ❌ Over-engineer - keep it simple
2. ❌ Add features not mentioned here
3. ❌ Use deprecated libraries
4. ❌ Hard-code values
5. ❌ Skip error handling
6. ❌ Ignore the safety rules

**Focus areas:**
- Correctness over cleverness
- Safety over speed
- Clarity over brevity
- Testability over complexity

---

## FINAL CHECKLIST

Before considering implementation complete:

**Database:**
- [ ] Model created with all required fields
- [ ] Migration generated and applied
- [ ] Django admin registered and functional
- [ ] Can create marks manually via admin

**Matching:**
- [ ] Normalization function implemented
- [ ] Bidirectional substring matching works
- [ ] Case-insensitive matching works
- [ ] Test data excluded from queries

**Processing:**
- [ ] Service class created
- [ ] Word footer injection works
- [ ] Excel marks injection works
- [ ] PROGRAMA files skipped
- [ ] No matches = no footer added

**Integration:**
- [ ] Download view modified
- [ ] Marks injected after replacements
- [ ] Temp files used correctly
- [ ] Error handling in place

**Safety:**
- [ ] Document body never modified
- [ ] Tables never modified
- [ ] Financial data preserved
- [ ] All tests pass

**Quality:**
- [ ] Code follows Django conventions
- [ ] Docstrings present
- [ ] Logging added
- [ ] No hard-coded values

---

## EXAMPLE PROMPT TO AI

```
I need you to implement an Audit Mark system in my Django project.

Context:
- Django 5.0.6
- Users download Word/Excel audit documents
- Need to automatically add audit mark symbols to footers

Requirements:
[Paste this entire AUDIT_MARK_PROMPT.md file]

Please implement:
1. Database model
2. Matching algorithm
3. Document processing service
4. Footer injection for Word
5. Marks section for Excel
6. Integration with existing download view

Make sure to follow all safety rules and handle all special cases.
```

---

**This prompt contains everything AI needs to implement the audit mark system correctly and safely.**
