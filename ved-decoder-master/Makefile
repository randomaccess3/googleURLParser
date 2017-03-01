
all: proto/ved_pb2.py

proto/ved_pb2.py:proto/ved.proto
	protoc -I. --python_out=. proto/ved.proto

	#patch the generated code (I hate this part!)
	# cat proto/ved_pb2.py|sed 's/google./googlepb./' > proto/ved_pb2.py.txt
	# mv proto/ved_pb2.py.txt proto/ved_pb2.py
