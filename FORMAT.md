# Overview

The HEBI Robot Configuration format has a root "robot" XML element, which contains a number of "robot model element" XML elements.  The structure of these robot model elements describe how they are connected.

Examples of this format in use can be seen in the kits in this directory.

## Version and versioning

The following specification is version 1.1.0 of this format.

The version numbering follows semantic versioning practices. Major version changes (e.g., 1.x.x->2.x.x) imply non-backwards compatible changes, whereas minor version changes (e.g., 1.3.0->1.4.0) imply backwards compatibility: existing robot configuration files will work with the updated specification, although files specifically using the newer specification may not be supported by tools using an older version of the standard.  Revision changes (1.4.2 -> 1.4.3) imply only clarification of the documentation, and should be treated as compatible.  Each new version change of the specification will be associated with a tag/release in this repository.

## Terms

When the term _whitespace_ is used in this document, it will refer to the ASCII space, tab, carriage return, and new line characters (values in the string " \t\r\n").

The attributes supported by the elements are of several basic types, described in more detail at the bottom of this document.

* [enums](#enums) (possible string values for an attribute)
* Basic [floating point](#floating-point) numbers
* [floating point formulas](#floating-point-formula) combining numbers, ()+-/* operators, and the constant `pi`
* [rotation matrix](#rotation-matrix) values, either in `Rx/Ry/Rz` shorthand or all entries of the matrix
* [translation vector](#translation-vector) values, containing x/y/z position

## Root element: `<robot>` 

The robot element is the root element of a robot model.

**Required Attributes for v > 1.0.0**
- `version` (enum) Specifies the version number of the HRDF format used to define this file.  To allow parsing of v1.0.0 files, this defaults to `1.0.0` if not given.  The rules used to parse the file are defined by the given version.  For example, a `mass_offset` attribute on an actuator may cause a parsing error if this attribute is not given, or is set to `1.0.0`. Supported values are:
  - 1.0.0
  - 1.1.0

**Optional Attributes**
- `rot` (rotation matrix) specify the rotation of the base frame of the model; defaults to identity matrix.
- `trans` (translation vector) specify the translation to the base frame of the model; defaults to (0,0,0)

**Example**
```xml
<robot rot="1 0 0 0 1 0 0 0 1" trans="0 0 0"/>
```

The `robot` element can only contain [`robot element`](robot-elements) subelements, which are described below.

## Robot Elements

Each "robot element" element has an assumed input interface, and one output interface. It may or may not have mass and inertia, depending on its type.

Note that the parsing of the element name (e.g., `actuator`) is case sensitive, and so `Actuator` will generate and error.

### `<actuator>`

The actuator element represents actuators such as the X5-4.  It is assumed to have a mass and inertia, as well as an output interface.  All actuators have one output interface.  It is assumed that there is a single associated degree of freedom in the robot model with this element.

**Required attributes:**
- `type` (string/enum) Currently supported values:
  - X5-1
  - X5-4
  - X5-9
  - X8-3
  - X8-9
  - X8-16

**Example:**

```xml
<actuator type="X5-9"/>
```

### `<link>`

The link element refers to a parameterized rigid body with two parameters (extension and twist).  All links have one output interface.

**Required attributes:**
- `type` (string/enum) Currently supported values:
  - X5
  - X5Inline
  - X5InlineIn
  - X5InlineOut
- `extension` (floating point formula, meters)
- `twist` (floating point formula, radians)

**Example:**

```xml
<link type="X5" extension="0.25" twist="pi/2"/>
```

### `<bracket>`

The bracket element refers to a rigid body that connects modules, such as a light wrist bracket.  All brackets have one output interface.

**Required attributes:**
- `type` (string/enum) supported values are:
  - X5LightLeft
  - X5LightRight
  - X5HeavyLeftInside
  - X5HeavyLeftOutside
  - X5HeavyRightInside
  - X5HeavyRightOutside

### `<rigid-body>`

The rigid body refers to a solid body with mass and one output.

**Required attributes:**
`mass` (floating point formula, kg)

**Optional attributes:**
- `com_rot` (rotation matrix) the orientation of the center of mass (used for simplifying the inertia tensor description if desired).  Defaults to identity.
- `com_trans` (translation vector, m) The position of the center of mass.  Defaults to (0,0,0).
- `output_rot` (rotation matrix): the orientation of the output frame.  Defaults to identity.
- `output_trans` (translation vector, m): The position the output frame.  Defaults to (0,0,0).

- `ixx`, `iyy`, `izz`, `ixy`, `ixz`, `iyz` (floating point formulae, kg m^2) The 6 elements of the inertia tensor, relative to the COM frame as given above.  Each defaults to 0 (note, this means overall default is a point mass).

**Example:**

```xml
<rigid-body mass="0.5" com_trans="0.25 0 0" output_rot="Rx(pi/4)" output_trans="0.5 0 0"/>
```

### `<joint>`

The joint refers to a massless degree of freedom.

**Required attributes:**
- `axis` (string/enum) This can be a rotational or translational degree of freedom about a principal coordinate axis; supported values are:
  - rx
  - ry
  - rz
  - tx
  - ty
  - tz

**Example:**

```xml
<joint axis="rx"/>
```

### Offsetting and overwriting dynamic properties

The built in robot model elements (`actuator`, `link`, and `bracket`) all have attributes that allow modification or overwriting of certain properties.

**Offset**
The optional offset attributes set a constant offset from the library values (e.g., to account for an additional weight on a module).

- `mass_offset` (floating point formula, kg) offset to be added (or subtracted) to the mass
- `com_trans_offset` (translation vector) offset to be added to the center of mass position

**Override**
The optional override attributes completely override the library values.  These have the same meaning/types as for the `rigid_body` element.
- `mass`
- `com_rot`
- `com_trans`
- `ixx`
- `iyy`
- `izz`
- `ixy`
- `ixz`
- `iyz`

Note: the HRDF file is ill-formed and should generate a parsing error if both `mass` and `mass_offset` attributes are defined, and similarly should fail if both `com_trans` and `com_trans_offset` elements are defined.

**Example:**

```xml
<actuator type="X5-9" mass_offset="0.2"/>
```

### Connecting Robot Model Elements

For the descriptions below, assume `<elem[0-9]*/>` is any of actuator, link, bracket, rigid-body, and joint, with all parameters defined as necessary.

The `robot` element can only contain `<elem>` subelements.  It contains an implicitly ordered list of them, with no minimum count:

```xml
<robot>
  <elem>
</robot>
```

When there is a list of `<elem>` elements, they are assumed to following each other in a kinematic chain - here, elem2 is more distal than elem1:

```xml
<robot>
  <elem1>
  <elem2>
</robot>
```

## Types

### enums

Enum types are lists of possible values that a certain attribute can have.

Implementation note: When parsing strings that are "enum" values (e.g., the "type" attribute of an actuator or link element), implementations should support reading these values in without regard to case (e.g., a value of "X5-1" or "x5-1" should both be interpreted correctly).  In the case of non-matching case, a warning should be provided by the API when importing the file.  If implementations support writing HRDF files, the case shown in this document should be written.

### floating point

A _floating point_ value is written as basic scientific notation.  Valid _floating point_ values include:

- `3.24`
- `0.324`
- `.324`
- `324`
- `3.24e2`
- `-3.24E-2`
- `-3.24e+2`
- `-32E4`
- `1.`

Invalid _floating point_ values include:

- `2.4.3`
- `2,000`
- `32,45`
- `3e2.4`
- `.`
- `- 1.3`
- `1. 02`

(A full railroad syntax diagram is available in the [Grammar](GRAMMAR.md) page)

### floating point formula

The _floating point formula_ type supports numeric values and simple formula elements. Basically, these support expressions using the _floating point_ type above, the constant pi (case sensitive), and allowing parenthesis (`()`), plus (`+`), minus (`-`), multiply (`*`), and divide (`/`) operators.  Whitespace is ignored (outside of the _floating point_ values)

Valid _floating point formula_ values include:

- `pi / 4`
- `1 + 4`
- `32*45`
- `1 + 2 / 3 - 4 * 5`
- `1 + 2 / (3 - 4) * 5`
- `(100 + 45) / (3*pi)`
- `32e-2*pi`

Invalid values include:

- `2 pi`
- `PI`

(A full formal grammar is available in the [Grammar](GRAMMAR.md) page)

### rotation matrix

Attributes which define a rotation matrix support either a row-major, whitespace delineated list of the 9 elements in a 3x3 rotation matrix, or a combination of axis-aligned rotations.

For the 9 element list, each element supports the basic _floating point_ attribute parsing described above.  For example,


```
1 0 0
0 1 0
0 0 1
```

or

```
1 0 0 0 1 0 0 0 1
```

would both be valid representations of an identity matrix.

For the combinations of axis-aligned rotations, the functions `Rx`, `Ry` and `Rz` are used to perform axis about rotations; their arguments can be any valid _floating point expression_ value:

```
Rz(pi/2)
```

or 

```
Rz(3 * pi/4 + 0.1)
```

These rotations can also be compounded by multiplying terms.

```
Rx(pi/2)*Rz(-pi/4)*Ry(pi/2)
```

(A full formal grammar is available in the [Grammar](GRAMMAR.md) page)

### translation vector

Attributes which define a translation vector support a whitespace delineated list of the 3 elements of a cartesian (x,y,z) vector.
