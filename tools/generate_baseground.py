#!/usr/bin/env python3

from dataclasses import dataclass
import os.path

output_dir: str = os.path.join(os.path.dirname(__file__), "../models/baseground/")
base_name: str = "ground_face"

@dataclass(frozen=True)
class Vector2:
	x: int
	y: int

@dataclass(frozen=True)
class Vector3:
	x: int
	y: int
	z: int

@dataclass
class Mesh:
	vertices: List[Vector3]
	faces: List[Tuple[int, int, int]]

	def to_obj(self) -> str:
		return "{vertices}\n{faces}".format(
			vertices = "\n".join(f"v {v.x} {v.y} {v.z}" for v in self.vertices),
			faces = "\n".join(f"f {f[0]}, {f[1]}, {f[2]}" for f in self.faces)
		)

@dataclass
class GridCoordinates:
	subtiles: int
	pos: Vector2
	size: Vector2
	def to_world(self, v: Vector2) -> Vector3:
		return Vector3(v.x * self.size.x / self.subtiles + self.pos.x, 0.0, v.y * self.size.y / self.subtiles + self.pos.y)
	def to_world_tuple(self, *vs: Vector3):
		return tuple(self.to_world(v) for v in vs)

type Triangle = Tuple[Vector3, Vector3, Vector3]

def generate_ground_triangles(grid: GridCoordinates) -> List[Triangle]:
	triangles: List[Triangle] = []
	for x in range(grid.subtiles):
		for y in range(grid.subtiles):
			if (x + y) % 2 == 1:
				triangles.append(grid.to_world_tuple(Vector2(x, y), Vector2(x+1, y), Vector2(x, y+1)))
				triangles.append(grid.to_world_tuple(Vector2(x, y+1), Vector2(x+1, y), Vector2(x+1, y+1)))
			else:
				triangles.append(grid.to_world_tuple(Vector2(x, y), Vector2(x+1, y), Vector2(x+1, y+1)))
				triangles.append(grid.to_world_tuple(Vector2(x, y+1), Vector2(x, y), Vector2(x+1, y+1)))
	return triangles

def triangles_to_mesh(triangles: List[Triangle]) -> Mesh:
	vertices: List[Vector3] = []
	faces: List[Tuple[int, int, int]] = []
	vertex_index: Dict[Vector3, int] = {}
	for triangle in triangles:
		face: List[int] = []
		for vert in triangle:
			if vert not in vertex_index:
				vertices.append(vert)
				vertex_index[vert] = len(vertices)
			face.append(vertex_index[vert])
		faces.append(tuple(face))
	return Mesh(vertices, faces)

def generate_mesh(subtiles: int) -> Mesh:
	grid: GridCoordinates = GridCoordinates(subtiles, Vector2(0, 0), Vector2(1, 1))
	triangles: List[Triangle] = generate_ground_triangles(grid)
	mesh: Mesh = triangles_to_mesh(triangles)
	return mesh

def write_mesh(subtiles):
	mesh: Mesh = generate_mesh(subtiles)
	obj: str = mesh.to_obj()
	name = f"{base_name}_{subtiles}_full.obj"
	path = os.path.join(output_dir, name)
	with open(path, "w") as f:
		f.write(obj)
	print("built", name)
write_mesh(64)
