#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧪 Running SageMaker Code Editor Unit Tests${NC}"

# Get project root
PROJ_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$PROJ_ROOT"

# Check if patches are applied
echo -e "${YELLOW}📋 Checking patch status...${NC}"
APPLIED_PATCHES=$(quilt applied 2>/dev/null || echo "")

if [ -z "$APPLIED_PATCHES" ]; then
    echo -e "${YELLOW}⚠️  No patches applied. Applying patches...${NC}"
    ./scripts/install.sh
    echo -e "${GREEN}✅ Patches applied successfully${NC}"
else
    echo -e "${GREEN}✅ Patches already applied${NC}"
fi

# Run TypeScript tests using Node.js
echo -e "${YELLOW}🔍 Running unit tests...${NC}"

# Check if Node.js and npx are available
if ! command -v node &> /dev/null || ! command -v npx &> /dev/null; then
    echo -e "${RED}❌ Node.js and npm are required to run tests${NC}"
    exit 1
fi

# Install required dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
npm install -g typescript
npm install --save-dev @types/node

# Compile and run each test file
TEST_DIR="tests"
FAILED_TESTS=0
TOTAL_TESTS=0

# First compile all TypeScript files
echo -e "${YELLOW}Compiling TypeScript files...${NC}"
if ! npx tsc --project "$TEST_DIR/tsconfig.json" --outDir /tmp/tests; then
    echo -e "${RED}❌ TypeScript compilation failed${NC}"
    exit 1
fi

for test_file in "$TEST_DIR"/*.test.ts; do
    if [ -f "$test_file" ]; then
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        test_name=$(basename "$test_file" .test.ts)
        
        echo -e "${YELLOW}Running $test_name tests...${NC}"
        
        # Run the compiled JavaScript
        if node "/tmp/tests/$(basename "$test_file" .ts).js"; then
            echo -e "${GREEN}✅ $test_name tests passed${NC}"
        else
            echo -e "${RED}❌ $test_name tests failed${NC}"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
        echo ""
    fi
done

# Summary
echo -e "${YELLOW}📊 Test Summary:${NC}"
echo -e "Total test suites: $TOTAL_TESTS"
echo -e "Failed test suites: $FAILED_TESTS"
echo -e "Passed test suites: $((TOTAL_TESTS - FAILED_TESTS))"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}💥 $FAILED_TESTS test suite(s) failed${NC}"
    exit 1
fi
