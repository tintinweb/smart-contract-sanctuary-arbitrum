// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {IRenderer} from "./IRenderer.sol";
import {DynamicBuffer} from "./DynamicBuffer.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Base64} from "solady/src/utils/Base64.sol";
import {ISpeedtracer} from "./ISpeedtracer.sol";

/// @author sammybauch.eth
/// @title  SpeedtracerTrack Renderer
/// @notice Render an SVG racetrack for a given seed
contract TrackRenderer is IRenderer {
    using DynamicBuffer for bytes;
    using Math for uint256;
    using Strings for uint256;

    uint256 public immutable greenFlag;

    uint64 private constant PRIME1 = 1572869;
    uint64 private constant PRIME2 = 29996224275833;

    uint64 private constant CANVAS_WIDTH = 1200;
    uint64 private constant CANVAS_HEIGHT = 1950;
    uint64 private constant CANVAS_OFFSET = 240;

    uint64 private constant minCurveDistance = 220;
    uint64 private constant newWidth = CANVAS_WIDTH - 2 * CANVAS_OFFSET;
    uint64 private constant newHeight = CANVAS_HEIGHT - 2 * CANVAS_OFFSET;
    uint64 private constant perimeter = 2 * newWidth + 2 * newHeight;

    ISpeedtracer public speedtracer;

    // ****************** //
    // *** INITIALIZE *** //
    // ****************** //

    constructor(address _speedtracer) {
        greenFlag = block.timestamp;
        speedtracer = ISpeedtracer(_speedtracer);
    }

    // ************* //
    // *** TRACK *** //
    // ************* //

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"SpeedTracer #',
                            tokenId.toString(),
                            '", "description":"SpeedTracer NFTs unlock premium token gated features.", "image": "',
                            this.svg(tokenId),
                            '"}'
                        )
                    )
                )
            )
        );
    }

    /// @notice Time-based ID for the current track for a new track every day.
    function currentId() public view returns (uint256) {
        uint256 secondsSinceDeploy = block.timestamp - greenFlag;
        uint256 daysSinceDeploy = secondsSinceDeploy / 86400; // 86400 seconds in a day
        return daysSinceDeploy + 1;
    }

    function svg(uint256 id) external view returns (string memory) {
        return string(render(id == 0 ? currentId() : id));
    }

    function path(uint256 id) external view returns (string memory) {
        (bytes memory d,) = renderTrack(id == 0 ? currentId() : id);
        return string(d);
    }

    function render(uint256 id) internal view returns (bytes memory _svg) {
        _svg = DynamicBuffer.allocate(2 ** 16);

        (bytes memory d, bytes memory points) = renderTrack(id);

        _svg.appendSafe(
            abi.encodePacked(
                "<svg viewBox='0 0 1200 1950' xmlns='http://www.w3.org/2000/svg'>",
                "<rect id='bg' width='100%' height='100%' fill='#23C552' />",
                // solhint-disable max-line-length
                "<path id='x' stroke-linecap='round' fill='none' stroke='#F84F31' stroke-width='100' stroke-linejoin='round' d='",
                d,
                "' /><path id='t' stroke-linecap='round' fill='none' stroke='black' stroke-width='88' stroke-linejoin='round' d='",
                d,
                "' /><path id='mid' fill='none' stroke='white' stroke-dasharray='24, 48' stroke-width='4' d='",
                d,
                // solhint-enable max-line-length
                "' />",
                points,
                "</svg>"
            )
        );
    }

    /// @notice Generate a bytes string containing the SVG path data for a racetrack.
    /// @param id The seed for the racetrack
    /// @return track The SVG path data for the racetrack
    /// @return circles The SVG circles for the racetrack
    /// @dev Return value can be used in the `d` attribute of an SVG path element
    function renderTrack(uint256 id)
        internal
        view
        returns (bytes memory track, bytes memory circles)
    {
        if (address(speedtracer) == address(0)) {
            return renderGeneratedTrack(id);
        }

        if (speedtracer.customTracks(id).length > 0) {
            return (speedtracer.customTracks(id), "");
        }

        return renderGeneratedTrack(id);
    }

    /// @notice Generate a bytes string containing the SVG path data for a racetrack.
    /// @param id The seed for the racetrack
    /// @return track The SVG path data for the racetrack
    /// @return circles The SVG circles for the racetrack
    /// @dev Return value can be used in the `d` attribute of an SVG path element
    function renderGeneratedTrack(uint256 id)
        internal
        pure
        returns (bytes memory track, bytes memory circles)
    {
        uint256 seed = pseudoRandom(id);

        Point[] memory points = generateRacetrack(seed);
        circles = DynamicBuffer.allocate(2 ** 16);
        track = DynamicBuffer.allocate(2 ** 16);
        track.appendSafe(
            abi.encodePacked(
                "M ",
                Strings.toString(points[0].x),
                ",",
                Strings.toString(points[0].y)
            )
        );
        circles.appendSafe(circle(points[0], 0, 2));

        uint256 currentSeed = seed;
        ControlPoint memory cp1;
        ControlPoint memory cp2;
        uint8 prevCurvType;

        for (uint64 i = 1; i < points.length - 1; i += 1) {
            // for (uint64 i = 1; i < 4; i += 1) {
            Point memory point = points[i];
            currentSeed = nextRandom(currentSeed);
            uint256 distance = distanceBetweenPoints(points[i - 1], point);
            uint8 curveType = (distance < minCurveDistance) ? 0 : 1; //uint8(currentSeed % 2);
            if (point.x == 0 && point.y == 0) continue;
            if (i == 1) {
                track.appendSafe(
                    abi.encodePacked(
                        " L ",
                        Strings.toString(point.x),
                        ",",
                        Strings.toString(point.y)
                    )
                );

                circles.appendSafe(circle(point, i, 2));

                prevCurvType = 0;
            } else if (curveType == 0) {
                // Straight segments become curves that are tangent to the previous curve
                (cp1, cp2) = calculateContinuity(
                    points[i - 1],
                    // ControlPoint({
                    //     x: int256(points[i - 1].x),
                    //     y: int256(points[i - 1].y)
                    // }),
                    cp1,
                    cp2,
                    point
                );

                track.appendSafe(
                    abi.encodePacked(
                        " C ",
                        intString(cp1.x), // here - cp2.x sometimes works better
                        ",",
                        intString(cp1.y),
                        " ",
                        intString(cp2.x), // here - cp2.x sometimes works better
                        ",",
                        intString(cp2.y),
                        " ",
                        Strings.toString(point.x),
                        ",",
                        Strings.toString(point.y)
                    )
                );

                circles.appendSafe(circle(point, i, 2));
                circles.appendSafe(circle(cp1, i, 0));
                circles.appendSafe(circle(cp2, i, 1));
                prevCurvType = 1;
            } else {
                if (prevCurvType > 0) {
                    // cp1 = calculateFirstControlPoint(
                    //     points[i - 1], cp2, points[i]
                    // );
                    cp2 = calculateSecondControlPoint(
                        points[i - 1], point, points[i + 1], cp2, currentSeed
                    );

                    track.appendSafe(
                        abi.encodePacked(
                            " S ",
                            intString(cp2.x),
                            ",",
                            intString(cp2.y),
                            " ",
                            Strings.toString(point.x),
                            ",",
                            Strings.toString(point.y)
                        )
                    );
                } else {
                    // Ensure continuity from a previous straight segment
                    // (cp1, cp2) = calculateContinuity(
                    //     points[i - 1],
                    //     // ControlPoint({
                    //     //     x: int256(points[i - 1].x),
                    //     //     y: int256(points[i - 1].y)
                    //     // }),
                    //     cp1,
                    //     cp2,
                    //     point
                    // );
                    (cp1, cp2) = calculateLineContinuity(
                        points[i - 2], points[i - 1], point
                    );

                    track.appendSafe(
                        abi.encodePacked(
                            " C ",
                            intString(cp1.x),
                            ",",
                            intString(cp1.y),
                            " ",
                            intString(cp2.x),
                            ",",
                            intString(cp2.y),
                            " ",
                            Strings.toString(point.x),
                            ",",
                            Strings.toString(point.y)
                        )
                    );
                    circles.appendSafe(circle(cp1, i, 0));
                }
                circles.appendSafe(circle(point, i, 2));

                circles.appendSafe(circle(cp2, i, 1));
                prevCurvType = curveType;
            }

            currentSeed = nextRandom(currentSeed);
        }

        // // Calculate the control points for the closing curve
        // cp1 = calculateFirstControlPoint(
        //     points[points.length - 2], cp2, points[points.length - 1]
        // );
        // cp2 = calculateSecondControlPoint(
        //     points[points.length - 1], points[0], points[1]
        // );

        // circles.appendSafe(circle(cp2, points.length, 1));

        // // Append the closing curve to the path
        track.appendSafe(
            abi.encodePacked(
                " S ",
                ((points[0].x - points[points.length - 1].x) / 3).toString(),
                ",",
                points[0].y.toString(),
                " ",
                points[0].x.toString(),
                ",",
                points[0].y.toString()
            )
        );
        // Calculate the control points for the closing curve
        uint256 _i = points.length - 1;
        cp1 = calculateFirstControlPoint(points[_i - 1], cp2, points[_i]);
        cp2 = calculateSecondControlPoint(
            points[_i - 1], points[_i], points[0], cp2, currentSeed
        );

        // Append the closing curve to the path
        // track.appendSafe(
        //     abi.encodePacked(
        //         " S ",
        //         // intString(cp1.x),
        //         // ",",
        //         // intString(cp1.y),
        //         // " ",
        //         intString(cp2.x),
        //         ",",
        //         intString(cp2.y),
        //         " ",
        //         points[0].x.toString(),
        //         ",",
        //         points[0].y.toString()
        //     )
        // );
        circles.appendSafe(circle(cp1, _i, 0));
        circles.appendSafe(circle(cp2, _i, 1));
    }

    function circle(Point memory cp, uint256 i, uint256 redBlue)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            "<circle cx='",
            Strings.toString(cp.x),
            "' cy='",
            Strings.toString(cp.y),
            redBlue == 0
                ? "' r='6' fill='red' />"
                : redBlue == 1
                    ? "' r='8' fill='blue' />"
                    : "' r='10' fill='green' />",
            "<text font-size='32' x='",
            Strings.toString(cp.x + 10 * redBlue),
            "' y='",
            Strings.toString(cp.y + 10),
            "' fill='white'>",
            Strings.toString(i),
            "</text>"
        );
    }

    function circle(ControlPoint memory cp, uint256 i, uint256 redBlue)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            "<circle cx='",
            intString(cp.x),
            "' cy='",
            intString(cp.y),
            redBlue == 0
                ? "' r='6' fill='red' />"
                : redBlue == 1
                    ? "' r='8' fill='blue' />"
                    : "' r='10' fill='green' />",
            "<text font-size='32' x='",
            intString(cp.x),
            "' y='",
            intString(cp.y + 10),
            "' fill='white'>",
            Strings.toString(i),
            "</text>"
        );
    }

    function pseudoRandom(uint256 seed) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed))) % PRIME2;
    }

    function nextRandom(uint256 seed) private pure returns (uint256) {
        return (seed * PRIME1) % PRIME2;
    }

    struct Point {
        uint256 x;
        uint256 y;
    }

    struct ControlPoint {
        int256 x;
        int256 y;
    }

    function generateRacetrack(uint256 seed)
        private
        pure
        returns (Point[] memory)
    {
        uint256 currentSeed = pseudoRandom(seed);
        uint8 numCols = 4; //3 + uint8(nextRandom(currentSeed) % 5); // 5 possible values: 3, 4, 5, 6, 7

        // uint8 minRows = numCols + 1;
        uint8 numRows = 6;
        // minRows + uint8(nextRandom(currentSeed) % (6 - minRows + 1));

        uint8 numPoints = (numRows * 2) + (numCols * 2) - 8;
        Point[] memory racetrack = new Point[](numPoints);
        uint8 i = 0;

        // Top row
        for (uint8 col = 0; col < numCols - 1; col++) {
            uint256 x = (newWidth * col) / (numCols - 1)
                + (nextRandom(currentSeed) % (newWidth / (numCols - 1)))
                + CANVAS_OFFSET;
            uint256 y = (nextRandom(currentSeed) % (newHeight / (numRows - 1)))
                + CANVAS_OFFSET;

            racetrack[i] = Point(x, y);
            currentSeed = nextRandom(currentSeed);
            i++;
        }

        // Right column
        for (uint8 row = 1; row < numRows - 2; row++) {
            uint256 x = (CANVAS_OFFSET + CANVAS_WIDTH / 2)
                + (nextRandom(currentSeed) % (newWidth / 2)) - CANVAS_OFFSET / 2;

            uint256 y = (newHeight * row) / (numRows - 1)
                + (nextRandom(currentSeed) % (newHeight / (numRows - 1)));

            Point memory a = racetrack[i - 2];
            Point memory b = racetrack[i - 1];
            Point memory c = Point(x, y);

            if (pointsDistanceValid(a, b, c)) {
                racetrack[i] = c;
                i++;
            } else {
                racetrack[i - 1] = c;
            }
            currentSeed = nextRandom(currentSeed);
        }

        // Bottom row
        for (uint8 col = numCols - 2; col > 0; col--) {
            uint256 x = (newWidth * col) / (numCols - 1)
                + (nextRandom(currentSeed) % (newWidth / (numCols - 1)))
                + CANVAS_OFFSET;
            uint256 y = (newHeight * (numRows - 2)) / (numRows - 1)
                + (nextRandom(currentSeed) % (newHeight / (numRows - 1)))
                + CANVAS_OFFSET;

            Point memory a = racetrack[i - 2];
            Point memory b = racetrack[i - 1];
            Point memory c = Point(x, y);

            if (pointsDistanceValid(a, b, c)) {
                racetrack[i] = c;
                i++;
            } else {
                racetrack[i - 1] = c;
            }
            currentSeed = nextRandom(currentSeed);
        }

        // Left column
        for (uint8 row = numRows - 2; row > 1; row--) {
            uint256 x =
                (nextRandom(currentSeed) % (newWidth / 3)) + CANVAS_OFFSET;

            uint256 y = (newHeight * row) / (numRows - 1)
                + (nextRandom(currentSeed) % (newHeight / (numRows - 1)));

            Point memory a = racetrack[i - 2];
            Point memory b = racetrack[i - 1];
            Point memory c = Point(x, y);

            if (pointsDistanceValid(a, b, c)) {
                racetrack[i] = c;
                i++;
            } else {
                racetrack[i - 1] = c;
            }
            currentSeed = nextRandom(currentSeed);
        }

        return racetrack;
    }

    function pointsDistanceValid(Point memory a, Point memory b, Point memory c)
        private
        pure
        returns (bool valid)
    {
        bool skip = distanceBetweenPoints(a, c) > minCurveDistance;
        bool consec = distanceBetweenPoints(b, c) > minCurveDistance;
        valid = skip && consec;
    }

    int256 private constant K = 2;
    int256 private constant M = 2;
    int256 private constant gamma = 15;
    int256 private constant delta = 15;
    int256 private constant angleThreshold = 1;

    /// @dev Calculate the control points for a Bezier curve with G1 and G2 continuity
    /// @param p0 The first point of the previous segment
    /// @param p1 The first control point of the previous segment
    /// @param p3 The end point of the previous segment
    function calculateLineContinuity(
        Point memory p0,
        Point memory p1,
        Point memory p3
    )
        internal
        pure
        returns (ControlPoint memory cp1, ControlPoint memory cp2)
    {
        // Ensure G1 continuity by making cp1 collinear with p0 and p1
        int256 ratio = 8; // Using ratio of 1.5 (3/2)
        cp1.x = int256(p1.x) + (int256(p1.x) - int256(p0.x)) * 2 / ratio;
        cp1.y = int256(p1.y) + (int256(p1.y) - int256(p0.y)) * 2 / ratio;
        uint256 minDistance = 400;

        // if (
        //     // distanceBetweenPoints(prevControlPoint, cp1) < minDistance
        //     distanceBetweenPoints(p1, cp1) < minDistance
        // ) {
        //     // || distanceBetweenPoints(nextPoint, cp1) < minDistance

        //     int256 sign = cp1.x >= int256(p0.x) ? int256(-1) : int256(1);

        //     if (distanceBetweenPoints(p1, cp1) < minDistance) {
        //         sign = 2;
        //     }
        //     cp1.x = 400; // int256(p0.x) + sign * int256(minDistance);
        // }

        cp2.x = (int256(cp1.x) + int256(p3.x)) / 2;

        // Calculate the difference between cp1.y and p3.y
        int256 minY = int256(p3.y) < cp1.y ? cp1.y - int256(p3.y) : int256(p3.y);
        // Set the largest acceptable value to p3.y
        int256 maxY = int256(p3.y) / 2;

        // Calculate cp2.y using the previous approach with the custom ratio
        cp2.y = int256(cp1.y) + (int256(p1.y) - int256(p0.y)) / ratio;

        // Ensure cp2.y falls within the acceptable range
        if (cp2.y < minY) {
            cp2.y = minY;
        } else if (cp2.y > maxY) {
            cp2.y = maxY;
        }
        // Adjust control point cp2 for better G2 continuity and rounding
        cp2.x = int256(cp1.x) + (int256(cp2.x) - int256(cp1.x)) * 2 / 4;
        cp2.y = int256(cp1.y) + (int256(cp2.y) - int256(cp1.y)) / 4;
    }

    uint256 private constant constantMultiplier = 1e6;

    /// @dev Calculate the control points for a Bezier curve with G1 and G2 continuity
    /// @param p0 The end point of the previous curve
    /// @param p1 The first control point of the previous curve
    /// @param p2 The second control point of the previous curve
    /// @param p3 The end point of the current curve
    function calculateContinuity(
        Point memory p0, // points[i - 1],
        ControlPoint memory p1, // cp1
        ControlPoint memory p2, // cp2
        Point memory p3 // point
    )
        internal
        pure
        returns (ControlPoint memory cp1, ControlPoint memory cp2)
    {
        // 2. Tangent continuity (G1): The tangent at the end of previos segment (from p2 to p3)
        // must be the same as the tangent at the beginning of this segment (from p3 to cp1).
        // This means that P2, P3, and cp1 must be collinear (lie along a straight line).

        // In our output, blue(n-1), green, and red(n) points must be collinear.

        // The direction and ratio of the distances between these points are important.
        // For example, if P3 is the midpoint between P2 and Q1, the tangents at P3/Q0 will be continuous.

        uint256 xDist = abs(int256(p3.x) - int256(p0.x));
        uint256 yDist = abs(int256(p3.y) - int256(p0.y));

        uint256 length =
            sqrt(uint256((xDist) * (xDist)) + uint256((yDist) * (yDist)));

        uint256 maxDistance = length - (length / 3);
        int256 ratio = 5; // Using ratio of 1.5 (3/2)
        cp1.x = int256(p3.x) + (int256(p3.x) - int256(p2.x)) * 2 / ratio;
        cp1.y = int256(p3.y) + (int256(p3.y) - int256(p2.y)) * 2 / ratio;
        cp1 = clampControlPoint(p0, cp1, maxDistance);

        int256 cp2x = int256(2) * int256(cp1.x) - int256(p3.x)
            + M * (int256(p2.x) - int256(2) * int256(p1.x) + int256(p0.x));

        cp2.x = cp2x < 0 ? int64(CANVAS_OFFSET) : cp2x;

        cp2.y = int256(2) * int256(cp1.y) - int256(p3.y)
            + M * (int256(p2.y) - int256(2) * int256(p1.y) + int256(p0.y));

        cp2 = clampControlPoint(p0, cp2, maxDistance);

        // if (xDist >= yDist) {
        //     // moving more horizontally
        //     if (p0.x > p3.x) {
        //         // moving left
        //         if (cp1.x > Math.max(p0.x, p3.x)) {
        //             cp1.x = Math.max(p0.x, p3.x);
        //         }
        //         if (cp2.x < Math.min(p0.x, p3.x)) {
        //             cp2.x = cp1.x - ((cp1.x - p3.x) / 2);
        //         }
        //     } else {
        //         // moving right
        //         if (cp1.x < Math.min(p0.x, p3.x)) {
        //             cp1.x = Math.min(p0.x, p3.x); // + 100;
        //         }
        //         if (cp2.x > Math.max(p0.x, p3.x)) {
        //             cp2.x = cp1.x + ((cp1.x - p3.x) / 2);
        //             cp2.x = Math.max(p0.x, p3.x);
        //         }
        //     }
        // } else {
        //     // moving more vertically
        //     if (p0.y > p3.y) {
        //         // moving up
        //         // we want to flip control points across p3, pulling the curve towards the perimeter

        //         if (cp1.y < Math.max(p0.y, p3.y)) {
        //             cp1.y = Math.max(p0.y, p3.y);
        //         }
        //         if (cp2.y < Math.min(p0.y, p3.y)) {
        //             cp2.y = cp1.y - ((cp1.y - p3.y) / 2);
        //         }
        //     } else {
        //         // moving down
        //         if (cp1.y < Math.min(p0.y, p3.y)) {
        //             cp1.y = Math.min(p0.y, p3.y);
        //         }
        //         if (cp2.y > Math.max(p0.y, p3.y)) {
        //             cp2.y = cp1.y + ((cp1.y - p3.y) / 2);
        //         }
        //     }
        // }

        // Additional constraints for situations where control points are close together
        // int256 angleCos = calculateTangentAngleCos(p0, p1, p2, p3, cp1);

        // if (
        //     angleCos
        //         > int256(
        //             int256(constantMultiplier) * int256(constantMultiplier)
        //                 - (angleThreshold * angleThreshold)
        //         )
        // ) {
        //     uint256 controlPointsDistance = distanceBetweenPoints(p2, cp1);

        //     if (
        //         controlPointsDistance
        //             < 10 * uint256(constantMultiplier) * uint256(constantMultiplier)
        //     ) {
        //         int256 alpha = 1; // Adjust this value for better control over the adjustment
        //         cp2 = adjustControlPointDistance(p3, p2, maxDistance, alpha);
        //         cp1 = adjustControlPointDistance(p3, cp1, maxDistance, alpha);
        //     }
        // }
    }

    function abs(int256 x) private pure returns (uint256) {
        return x >= 0 ? uint256(x) : uint256(x * -1);
    }

    function clamp(int256 value, int256 minValue, int256 maxValue)
        internal
        pure
        returns (int256)
    {
        return min(max(value, minValue), maxValue);
    }

    function distanceBetweenPoints(Point memory a, Point memory b)
        internal
        pure
        returns (uint256)
    {
        int256 dx = int256(a.x) - int256(b.x);
        int256 dy = int256(a.y) - int256(b.y);
        return sqrt(uint256(dx * dx + dy * dy));
    }

    function distanceBetweenPoints(Point memory a, ControlPoint memory b)
        internal
        pure
        returns (uint256)
    {
        int256 dx = int256(a.x) - int256(b.x);
        int256 dy = int256(a.y) - int256(b.y);
        return sqrt(uint256(dx * dx + dy * dy));
    }

    function distanceBetweenPoints(ControlPoint memory a, ControlPoint memory b)
        internal
        pure
        returns (uint256)
    {
        int256 dx = int256(a.x) - int256(b.x);
        int256 dy = int256(a.y) - int256(b.y);
        return sqrt(uint256(dx * dx + dy * dy));
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a <= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (int256) {
        return a < b ? int256(a) : int256(b);
    }

    function max(uint256 a, uint256 b) internal pure returns (int256) {
        return a > b ? int256(a) : int256(b);
    }

    function sqrt(uint256 x) private pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    function intString(int256 n) internal pure returns (string memory) {
        if (n == 0) {
            return "0";
        }
        if (n > 0) {
            return uint256(n).toString();
        }

        return string(abi.encodePacked("-", uint256(n * -1).toString()));
    }

    // AI shit

    function calculateFirstControlPoint(
        Point memory prevEndPoint,
        ControlPoint memory prevControlPoint,
        Point memory endPoint
    ) internal pure returns (ControlPoint memory) {
        int256 vecX = int256(prevEndPoint.x) - int256(prevControlPoint.x);
        int256 vecY = int256(prevEndPoint.y) - int256(prevControlPoint.y);

        int256 newControlPointX = int256(endPoint.x) + vecX;
        int256 newControlPointY = int256(endPoint.y) + vecY;

        if (abs(vecY) > abs(vecX)) {
            if (prevEndPoint.y < endPoint.y) {
                newControlPointY = int256(prevEndPoint.y) + (vecY * 2 / 3);
                newControlPointY = min(
                    newControlPointY,
                    int256(max(int256(prevEndPoint.y), int256(endPoint.y)))
                );
            } else {
                newControlPointY = int256(prevEndPoint.y) - (vecY * 2 / 3);
            }
        } else {
            if (prevEndPoint.x < endPoint.x) {
                newControlPointX = int256(prevEndPoint.x) + (vecX * 2 / 3);
                newControlPointX = min(
                    newControlPointX,
                    int256(max(int256(prevEndPoint.x), int256(endPoint.x)))
                );
            } else {
                newControlPointX = int256(endPoint.x) - (vecX * 2 / 3);
                newControlPointX = min(
                    newControlPointX,
                    int256(max(int256(prevEndPoint.x), int256(endPoint.x)))
                );
            }
        }

        return ControlPoint(newControlPointX, newControlPointY);
    }

    function calculateSecondControlPoint(
        Point memory prevPoint,
        Point memory currentPoint,
        Point memory nextPoint,
        ControlPoint memory prevControlPoint,
        uint256 seed
    ) internal pure returns (ControlPoint memory cp) {
        int256 vecX = int256(currentPoint.x) - int256(prevPoint.x);
        int256 vecY = int256(currentPoint.y) - int256(prevPoint.y);

        // 1013,1127
        // 939,1645
        // (1013) + (939 - 1013) / 2 = 976
        // Set the control point's x and y values to the midpoint between prevPoint and currentPoint
        cp.x = int256(prevPoint.x)
            + (int256(currentPoint.x) - int256(prevPoint.x)) / 2;
        cp.y = int256(prevPoint.y)
            + (int256(currentPoint.y) - int256(prevPoint.y)) / 2;

        // Introduce a random factor to adjust the control point's position along the line segment
        uint256 randomFactor = seed % 100;
        int256 adjustment = int256(randomFactor) - 50; // Range: -50 to 49

        // Apply the adjustment to the control point's x and y values
        cp.x += adjustment;
        cp.y += adjustment;
        uint256 minDistance = 172;
        if (abs(vecY) > abs(vecX)) {
            // when moving vertically, clamp the X value to avoid loop-backs
            cp.x = clamp(
                cp.x,
                min(prevPoint.x, currentPoint.x),
                max(prevPoint.x, currentPoint.x)
            );

            // If cps are too close, move them apart
            if (
                distanceBetweenPoints(prevControlPoint, cp) < minDistance
                    || distanceBetweenPoints(currentPoint, cp) < minDistance
                    || distanceBetweenPoints(nextPoint, cp) < minDistance
            ) {
                int256 sign =
                    cp.x >= int256(currentPoint.x) ? int256(-1) : int256(1);

                if (distanceBetweenPoints(nextPoint, cp) < minDistance) {
                    sign = 2;
                }
                cp.x = int256(prevPoint.x) + sign * int256(minDistance);
            }

            // Determine if the control point's X value is within the range of the current and next points' X values
            bool isWithinRangeX = (
                int256(currentPoint.x) >= min(prevPoint.x, nextPoint.x)
            ) && int256(currentPoint.x) <= max(prevPoint.x, nextPoint.x);

            // Adjust the control point's X value to reverse the convexity of the curve if needed
            if (isWithinRangeX) {
                int256 sign =
                    currentPoint.x >= prevPoint.x ? int256(-1) : int256(1);
                cp.x = int256(prevPoint.x)
                    - sign * int256(abs(int256(prevPoint.x) - int256(cp.x)));
            }
        } else {
            // when moving horizontally, clamp the Y value to avoid loop-backs
            cp.y = clamp(
                cp.y,
                min(prevPoint.y, currentPoint.y),
                max(prevPoint.y, currentPoint.y)
            );
            // If cps are too close, move them apart
            if (distanceBetweenPoints(prevControlPoint, cp) < minDistance) {
                int256 sign =
                    cp.y >= int256(prevControlPoint.y) ? int256(1) : int256(-1);
                cp.y = int256(prevControlPoint.y) + sign * int256(minDistance);
            }

            // bool isWithinRangeY = (
            //     int256(currentPoint.y) >= min(prevPoint.y, nextPoint.y)
            // ) && int256(currentPoint.y) <= max(prevPoint.y, nextPoint.y);

            // // Adjust the control point's X value to reverse the convexity of the curve if needed
            // if (isWithinRangeY) {
            //     int256 sign =
            //         currentPoint.y >= prevPoint.y ? int256(-1) : int256(1);
            //     cp.x = int256(prevPoint.y)
            //         - sign * int256(abs(int256(prevPoint.y) - int256(cp.y)));
            // }
        }

        // C 770,502 774,404 786,220
        // S (564->864),228 1008,408

        //prevPoint = 786,220
        // cp1 = 770,502
        // cp2 = 774,404
        //currentPoint = 1008,408
        // => 564,228
        if (prevPoint.x < currentPoint.x && cp.x < prevControlPoint.x) {
            cp.x = cp.x * 2;
        }
        // if (prevPoint.y < currentPoint.y && currentPoint.y > nextPoint.y) {
        //     cp.x = int256(prevPoint.x) + int256(prevPoint.x)
        //         - int256(currentPoint.x);
        // }

        if (
            currentPoint.x < prevPoint.x
            // && prevControlPoint.x > int256(prevPoint.x)
            && cp.x < int256(currentPoint.x) && currentPoint.y > prevPoint.y
        ) {
            cp.x *= 2;
        }
        // // S 802,1494 666,1494
        // // S (970 -> 502),1532 362,1532
        // // S 256,1389 256,1246
        if (
            prevControlPoint.x > int256(currentPoint.x)
                && currentPoint.x > nextPoint.x
        ) {
            // cp.x = 864;
            cp.x = prevControlPoint.x
                - (int256(prevPoint.x) - int256(currentPoint.x));
        }

        if (cp.x < int64(CANVAS_OFFSET)) {
            cp.x = int64(CANVAS_OFFSET);
        }

        if (cp.x > int64(CANVAS_WIDTH)) {
            cp.x = int64(CANVAS_WIDTH);
        }

        if (cp.y < int64(CANVAS_OFFSET)) {
            cp.y = int64(CANVAS_OFFSET);
        }

        if (cp.y > int64(CANVAS_HEIGHT)) {
            cp.y = int64(CANVAS_HEIGHT);
        }
    }

    function clampControlPoint(
        Point memory p0,
        ControlPoint memory cp,
        uint256 maxDistance
    ) internal pure returns (ControlPoint memory _cp) {
        uint256 distance = sqrt(
            uint256(
                (int256(cp.x) - int256(p0.x)) * (int256(cp.x) - int256(p0.x))
            )
                + uint256(
                    (int256(cp.y) - int256(p0.y)) * (int256(cp.y) - int256(p0.y))
                )
        );

        if (distance > maxDistance) {
            int256 scaleFactor =
                int256(maxDistance * constantMultiplier / distance);
            int256 cp1x = int256(p0.x)
                + (scaleFactor * (int256(cp.x) - int256(p0.x)))
                    / int256(constantMultiplier);

            _cp.x = cp1x > 0 ? cp1x : int64(CANVAS_OFFSET);

            _cp.y = int256(p0.y)
                + (scaleFactor * (int256(cp.y) - int256(p0.y)))
                    / int256(constantMultiplier);
        }
    }

    function adjustControlPointDistance(
        Point memory p,
        Point memory q,
        uint256 distance,
        int256 scaleFactor
    ) internal pure returns (Point memory) {
        int256 x = int256(p.x)
            + scaleFactor * (int256(q.x) - int256(p.x)) / int256(constantMultiplier);
        int256 y = int256(p.y)
            + scaleFactor * (int256(q.y) - int256(p.y)) / int256(constantMultiplier);

        return Point(uint256(x), uint256(y));
    }

    function calculateTangentAngleCos(
        Point memory p0,
        Point memory p1,
        Point memory p2,
        Point memory p3,
        Point memory cp1
    ) internal pure returns (int256) {
        int256 tangent_P3_x = int256(p3.x) - int256(p2.x);
        int256 tangent_P3_y = int256(p3.y) - int256(p2.y);

        int256 tangent_Q0_x = int256(cp1.x) - int256(p3.x);
        int256 tangent_Q0_y = int256(cp1.y) - int256(p3.y);

        int256 dotProduct =
            tangent_P3_x * tangent_Q0_x + tangent_P3_y * tangent_Q0_y;
        uint256 magnitudesProduct = uint256(
            tangent_P3_x * tangent_P3_x + tangent_P3_y * tangent_P3_y
        ) * uint256(tangent_Q0_x * tangent_Q0_x + tangent_Q0_y * tangent_Q0_y);

        return dotProduct * int256(constantMultiplier * constantMultiplier)
            / int256(magnitudesProduct);
    }
}

// uint256 prevControlPointWeight = 3;
// uint256 newControlPointWeight = 1;
// uint256 totalWeight = (prevControlPointWeight + newControlPointWeight);
// uint256 scalingFactor = 2;

// function calculateControlPoint(
//     Point memory p0,
//     Point memory p1,
//     Point memory p2,
//     Point memory prevControlPoint,
//     uint256 seed
// ) private pure returns (Point memory newControlPoint) {
//     int256 xDirection = int256(p2.x) > int256(p1.x) ? int256(1) : -1;
//     int256 yDirection = int256(p2.y) > int256(p1.y) ? int256(1) : -1;
//     Point memory m1 = Point((p0.x + p1.x) / 2, (p0.y + p1.y) / 2);
//     Point memory m2 = Point((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);

//     // Calculate midpoint M between M1 and M2
//     Point memory m = Point((m1.x + m2.x) / 2, (m1.y + m2.y) / 2);

//     // Calculate vector V from M1 to M2 and scale it by factor k
//     uint256 vX = abs(int256(m2.x) - int256(m1.x));
//     uint256 vY = abs(int256(m2.y) - int256(m1.y));

//     // Scale vector V by factor k
//     vX = vX * (2);
//     vY = vY * (3);
//     // newControlPoint =
//     //     Point(uint256(int256(m.x) - vX), uint256(int256(m.y) - vY));
//     // c2 = Point(uint256(int256(m.x) + vX), uint256(int256(m.y) + vY));

//     // if xDistance < yDistance
//     // if (abs(int256(p2.x) - int256(p1.x)) < abs(int256(p2.y) - int256(p1.y)))
//     // {
//     //     // Path is moving more vertically
//     //     newControlPoint.x =
//     //         xDirection > 0 ? p2.x : uint256(int256(m.x) + vX);
//     //     newControlPoint.y = (p1.y + p2.y) / 2;
//     // } else {
//     //     // Path is moving more horizontally
//     //     newControlPoint.x = (p1.x + p2.x) / 2;
//     //     newControlPoint.y =
//     //         yDirection > 0 ? p1.y : uint256(int256(m.y) + vY); //yDirection > 0 ? p1.y : p2.y;
//     // }

//     if (p0.x > p1.x && p1.x > p2.x && yDirection > 0) {
//         //
//         // we should mirror the control point to avoid "waves"

//         newControlPoint.x = p2.x > 280 ? p2.x - 200 : p2.x; // - p1.x; // - (prevControlPoint.x - p1.x);
//         newControlPoint.y = p1.y + 80; // - p1.y; // - (prevControlPoint.y - p1.y);
//         return newControlPoint; // vX = vX * 2;
//     }

//     if (abs(int256(p2.x) - int256(p1.x)) < abs(int256(p2.y) - int256(p1.y)))
//     {
//         // Path is moving more vertically
//         newControlPoint.x = xDirection > 0 ? p2.x : uint256(m.x + vX);
//         newControlPoint.y = (p1.y + p2.y) / 2;
//     } else {
//         // Path is moving more horizontally
//         newControlPoint.x = (p1.x + p2.x) / 2;
//         newControlPoint.y =
//             yDirection > 0 ? p2.y : m.y > vY ? uint256((m.y) - vY) : m.y;
//     }
// }
// '<path stroke="grey" stroke-width="1" fill="none" d="M 160 0 L 160 1950" /><path stroke="white" stroke-width="1" fill="none" d="M 380 160 L 380 1950" /><path stroke="white" stroke-width="1" fill="none" d="M 600 160 L 600 1950" /><path stroke="white" stroke-width="1" fill="none" d="M 820 0 L 820 1950" /><path stroke="grey" stroke-width="1" fill="none" d="M 1040 0 L 1040 1950" />',
//                 '<path stroke="grey" stroke-width="1" fill="none" d="M 0 160 L 1200 160" /><path stroke="white" stroke-width="1" fill="none" d="M 0 430 L 1200 430" /><path stroke="white" stroke-width="1" fill="none" d="M 0 700 L 1200 700" /> <path stroke="white" stroke-width="1" fill="none" d="M 0 975 L 1200 975" /> <path stroke="white" stroke-width="1" fill="none" d="M 0 1300 L 1200 1300" /><path stroke="white" stroke-width="1" fill="none" d="M 0 1625 L 1200 1625" />',
// function _calculateSecondControlPoint(
//     Point memory prevEndPoint,
//     ControlPoint memory firstControlPoint,
//     Point memory endPoint
// ) internal pure returns (ControlPoint memory) {
//     int256 vecX = int256(firstControlPoint.x) - int256(prevEndPoint.x);
//     int256 vecY = int256(firstControlPoint.y) - int256(prevEndPoint.y);

//     int256 distX = int256(endPoint.x) - int256(prevEndPoint.x);
//     int256 distY = int256(endPoint.y) - int256(prevEndPoint.y);

//     int256 newControlPointX = int256(endPoint.x) + vecX;
//     int256 newControlPointY = int256(endPoint.y) + vecY;

//     // Adjust the control points' positions based on the relative distance between start and end points
//     if (abs(distY) > abs(distX)) {
//         newControlPointY = int256(endPoint.y) - (vecY * 2 / 3);
//         newControlPointY = min(
//             newControlPointY,
//             int256(max(int256(prevEndPoint.y), int256(endPoint.y)))
//         );
//     } else {
//         if (prevEndPoint.x < endPoint.x) {
//             newControlPointX = int256(endPoint.x) - (vecX * 2 / 3);
//             newControlPointX = // max(
//             min(
//                 newControlPointX,
//                 int256(max(int256(prevEndPoint.x), int256(endPoint.x)))
//             );
//         } else {
//             newControlPointX = int256(endPoint.x) - (vecX * 2 / 3);
//             newControlPointX = min(
//                 newControlPointX,
//                 int256(max(int256(prevEndPoint.x), int256(endPoint.x)))
//             );
//         }
//         // ),
//         // int256(min(int256(prevEndPoint.x), int256(endPoint.x)))
//     }

//     return ControlPoint(newControlPointX, newControlPointY);
// }

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/// @author frolic.eth
/// @title  Upgradeable renderer interface
/// @notice This leaves room for us to change how we return token metadata and
///         unlocks future capability like fully on-chain storage.
interface IRenderer {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)

pragma solidity ^0.8.17;

/// @title DynamicBuffer
/// @author David Huber (@cxkoda) and Simon Fremaux (@dievardump). See also
///         https://raw.githubusercontent.com/dievardump/solidity-dynamic-buffer
/// @notice This library is used to allocate a big amount of container memory
//          which will be subsequently filled without needing to reallocate
///         memory.
/// @dev First, allocate memory.
///      Then use `buffer.appendUnchecked(theBytes)` or `appendSafe()` if
///      bounds checking is required.
library DynamicBuffer {
    /// @notice Allocates container space for the DynamicBuffer
    /// @param capacity The intended max amount of bytes in the buffer
    /// @return buffer The memory location of the buffer
    /// @dev Allocates `capacity + 0x60` bytes of space
    ///      The buffer array starts at the first container data position,
    ///      (i.e. `buffer = container + 0x20`)
    function allocate(uint256 capacity)
        internal
        pure
        returns (bytes memory buffer)
    {
        assembly {
            // Get next-free memory address
            let container := mload(0x40)

            // Allocate memory by setting a new next-free address
            {
                // Add 2 x 32 bytes in size for the two length fields
                // Add 32 bytes safety space for 32B chunked copy
                let size := add(capacity, 0x60)
                let newNextFree := add(container, size)
                mstore(0x40, newNextFree)
            }

            // Set the correct container length
            {
                let length := add(capacity, 0x40)
                mstore(container, length)
            }

            // The buffer starts at idx 1 in the container (0 is length)
            buffer := add(container, 0x20)

            // Init content with length 0
            mstore(buffer, 0)
        }

        return buffer;
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Does not perform out-of-bound checks (container capacity)
    ///      for efficiency.
    function appendUnchecked(bytes memory buffer, bytes memory data)
        internal
        pure
    {
        assembly {
            let length := mload(data)
            for {
                data := add(data, 0x20)
                let dataEnd := add(data, length)
                let copyTo := add(buffer, add(mload(buffer), 0x20))
            } lt(data, dataEnd) {
                data := add(data, 0x20)
                copyTo := add(copyTo, 0x20)
            } {
                // Copy 32B chunks from data to buffer.
                // This may read over data array boundaries and copy invalid
                // bytes, which doesn't matter in the end since we will
                // later set the correct buffer length, and have allocated an
                // additional word to avoid buffer overflow.
                mstore(copyTo, mload(data))
            }

            // Update buffer length
            mstore(buffer, add(mload(buffer), length))
        }
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Performs out-of-bound checks and calls `appendUnchecked`.
    function appendSafe(bytes memory buffer, bytes memory data) internal pure {
        uint256 capacity;
        uint256 length;
        assembly {
            capacity := sub(mload(sub(buffer, 0x20)), 0x40)
            length := mload(buffer)
        }

        require(
            length + data.length <= capacity,
            "DynamicBuffer: Appending out of bounds."
        );
        appendUnchecked(buffer, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library to encode strings in Base64.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Base64.sol)
/// @author Modified from (https://github.com/Brechtpd/base64/blob/main/base64.sol) by Brecht Devos - <[email protected]>.
library Base64 {
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    function encode(bytes memory data, bool fileSafe, bool noPadding)
        internal
        pure
        returns (string memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                // Multiply by 4/3 rounded up.
                // The `shl(2, ...)` is equivalent to multiplying by 4.
                let encodedLength := shl(2, div(add(dataLength, 2), 3))

                // Set `result` to point to the start of the free memory.
                result := mload(0x40)

                // Store the table into the scratch space.
                // Offsetted by -1 byte so that the `mload` will load the character.
                // We will rewrite the free memory pointer at `0x40` later with
                // the allocated size.
                // The magic constant 0x0230 will translate "-_" + "+/".
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, sub("ghijklmnopqrstuvwxyz0123456789-_", mul(iszero(fileSafe), 0x0230)))

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, encodedLength)

                // Run over the input, 3 bytes at a time.
                for {} 1 {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(0, mload(and(shr(18, input), 0x3F)))
                    mstore8(1, mload(and(shr(12, input), 0x3F)))
                    mstore8(2, mload(and(shr(6, input), 0x3F)))
                    mstore8(3, mload(and(input, 0x3F)))
                    mstore(ptr, mload(0x00))

                    ptr := add(ptr, 4) // Advance 4 bytes.

                    if iszero(lt(ptr, end)) { break }
                }

                // Allocate the memory for the string.
                // Add 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(31)))

                // Equivalent to `o = [0, 2, 1][dataLength % 3]`.
                let o := div(2, mod(dataLength, 3))

                // Offset `ptr` and pad with '='. We can simply write over the end.
                mstore(sub(ptr, o), shl(240, 0x3d3d))
                // Set `o` to zero if there is padding.
                o := mul(iszero(iszero(noPadding)), o)
                // Zeroize the slot after the string.
                mstore(sub(ptr, o), 0)
                // Write the length of the string.
                mstore(result, sub(encodedLength, o))
            }
        }
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, false, false)`.
    function encode(bytes memory data) internal pure returns (string memory result) {
        result = encode(data, false, false);
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, fileSafe, false)`.
    function encode(bytes memory data, bool fileSafe)
        internal
        pure
        returns (string memory result)
    {
        result = encode(data, fileSafe, false);
    }

    /// @dev Decodes base64 encoded `data`.
    ///
    /// Supports:
    /// - RFC 4648 (both standard and file-safe mode).
    /// - RFC 3501 (63: ',').
    ///
    /// Does not support:
    /// - Line breaks.
    ///
    /// Note: For performance reasons,
    /// this function will NOT revert on invalid `data` inputs.
    /// Outputs for invalid inputs will simply be undefined behaviour.
    /// It is the user's responsibility to ensure that the `data`
    /// is a valid base64 encoded string.
    function decode(string memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                let decodedLength := mul(shr(2, dataLength), 3)

                for {} 1 {} {
                    // If padded.
                    if iszero(and(dataLength, 3)) {
                        let t := xor(mload(add(data, dataLength)), 0x3d3d)
                        // forgefmt: disable-next-item
                        decodedLength := sub(
                            decodedLength,
                            add(iszero(byte(30, t)), iszero(byte(31, t)))
                        )
                        break
                    }
                    // If non-padded.
                    decodedLength := add(decodedLength, sub(and(dataLength, 3), 1))
                    break
                }
                result := mload(0x40)

                // Write the length of the bytes.
                mstore(result, decodedLength)

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, decodedLength)

                // Load the table into the scratch space.
                // Constants are optimized for smaller bytecode with zero gas overhead.
                // `m` also doubles as the mask of the upper 6 bits.
                let m := 0xfc000000fc00686c7074787c8084888c9094989ca0a4a8acb0b4b8bcc0c4c8cc
                mstore(0x5b, m)
                mstore(0x3b, 0x04080c1014181c2024282c3034383c4044484c5054585c6064)
                mstore(0x1a, 0xf8fcf800fcd0d4d8dce0e4e8ecf0f4)

                for {} 1 {} {
                    // Read 4 bytes.
                    data := add(data, 4)
                    let input := mload(data)

                    // Write 3 bytes.
                    // forgefmt: disable-next-item
                    mstore(ptr, or(
                        and(m, mload(byte(28, input))),
                        shr(6, or(
                            and(m, mload(byte(29, input))),
                            shr(6, or(
                                and(m, mload(byte(30, input))),
                                shr(6, mload(byte(31, input)))
                            ))
                        ))
                    ))

                    ptr := add(ptr, 3)

                    if iszero(lt(ptr, end)) { break }
                }

                // Allocate the memory for the string.
                // Add 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(31)))
                // Zeroize the slot after the bytes.
                mstore(end, 0)
                // Restore the zero slot.
                mstore(0x60, 0)
            }
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/// @author sammybauch.eth
interface ISpeedtracer {
    function customTracks(uint256 tokenId)
        external
        view
        returns (bytes memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}