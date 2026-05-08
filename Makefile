#******************************************************************************
#* Project: Hospital Patient Triage & Bed Allocator
#* File: bed.h
#* Group: Group XX
#* Members: Muhammad Abdullah khan, Muhammad Zunair Haider, Waleed bin Nasir
#* Roll No.: 24F-0626,24F-590,24F-0516
#* Date: 2026-05-08
# ******************************************************************************/

CC      = gcc
CFLAGS  = -Wall -Wextra -pthread -std=c11 -I./include
LDFLAGS = -pthread -lrt
SRCDIR  = src
BINDIR  = .

# Allocator strategy: BEST_FIT (default), FIRST_FIT, WORST_FIT
ALLOC  ?= BEST_FIT
CFLAGS += -DALLOC_STRATEGY=$(ALLOC)

TARGETS = admissions_manager patient_simulator

.PHONY: all clean run valgrind test first_fit best_fit worst_fit

all: $(TARGETS)

run: all
	./scripts/start_hospital.sh $(ALLOC)

admissions_manager: $(SRCDIR)/admissions_manager.c include/patient.h include/bed.h include/ipc.h
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

patient_simulator: $(SRCDIR)/patient_simulator.c include/patient.h include/ipc.h
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

# Allocator strategy shortcuts
best_fit:
	$(MAKE) all ALLOC=BEST_FIT

first_fit:
	$(MAKE) all ALLOC=FIRST_FIT

worst_fit:
	$(MAKE) all ALLOC=WORST_FIT

test: all
	@echo "Running stress test..."
	./scripts/stress_test.sh

# Valgrind — run admissions_manager under leak checker
valgrind: admissions_manager patient_simulator
	@echo "Starting system under valgrind. Press Ctrl+C after 10s of traffic."
	valgrind --leak-check=full --track-origins=yes \
		--log-file=logs/valgrind.log \
		./admissions_manager &
	@sleep 2
	@echo "Alice|30|0|chest pain" > $(shell cat /tmp/hospital_triage.fifo 2>/dev/null || echo /tmp/hospital_triage.fifo)
	@sleep 15
	@kill $$(cat /tmp/hospital_admissions.pid 2>/dev/null) 2>/dev/null || true
	@echo "Valgrind report saved to logs/valgrind.log"

clean:
	rm -f $(TARGETS)
	rm -f logs/*.log logs/valgrind.log
	rm -f /tmp/hospital_triage.fifo /tmp/discharge_fifo
	rm -f /tmp/hospital_admissions.pid
	@echo "Clean complete."
