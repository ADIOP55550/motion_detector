public class BoundingBox {
    private double minX;
    private double maxX;
    private double minY;
    private double maxY;

    public BoundingBox(List<Point> points) {
        minX = Double.MAX_VALUE;
        maxX = Double.MIN_VALUE;
        minY = Double.MAX_VALUE;
        maxY = Double.MIN_VALUE;

        for (Point point : points) {
            double x = point.x;
            double y = point.y;

            if (x < minX) {
                minX = x;
            }
            if (x > maxX) {
                maxX = x;
            }
            if (y < minY) {
                minY = y;
            }
            if (y > maxY) {
                maxY = y;
            }
        }
    }

    public double getMinX() {
        return minX;
    }

    public double getMaxX() {
        return maxX;
    }

    public double getMinY() {
        return minY;
    }

    public double getMaxY() {
        return maxY;
    }
}
