.PHONY: doctor up logs shell list test verify validate down

doctor:
	./lab.sh doctor

up:
	./lab.sh up

logs:
	./lab.sh logs

shell:
	./lab.sh shell

list:
	./lab.sh list

test:
	./lab.sh test


validate:
	./lab.sh validate

down:
	./lab.sh down
